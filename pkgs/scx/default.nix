{ lib
, llvmPackages
, writeShellScript
, writeShellScriptBin
, fetchFromGitHub
, scx-common
, scx-bpfland
, scx-lavd
, scx-layered
, scx-rlfifo
, scx-rustland
, scx-rusty
, scx-stats
, pkg-config
, meson
, ninja
, bpftools_full
, elfutils
, zlib
, libbpf_git
, jq
, bash
}:

let
  fakeCargo = writeShellScriptBin "cargo" ''
    set -e
    if [ ''${3:-} = '--target-dir=rust/scx_utils' ]; then
      exit 0
    elif [ ''${3:-} = '--target-dir=rust/scx_rustland_core' ]; then
      exit 0
    elif [ ''${3:-} = '--target-dir=scheds/rust/scx_bpfland' ]; then
      mkdir -p /build/source/build/scheds/rust/scx_bpfland
      cp -r ${scx-bpfland} /build/source/build/scheds/rust/scx_bpfland/release
      exit 0
    elif [ ''${3:-} = '--target-dir=scheds/rust/scx_lavd' ]; then
      mkdir -p /build/source/build/scheds/rust/scx_lavd
      cp -r ${scx-lavd} /build/source/build/scheds/rust/scx_lavd/release
      exit 0
    elif [ ''${3:-} = '--target-dir=scheds/rust/scx_layered' ]; then
      mkdir -p /build/source/build/scheds/rust/scx_layered
      cp -r ${scx-layered} /build/source/build/scheds/rust/scx_layered/release
      exit 0
    elif [ ''${3:-} = '--target-dir=scheds/rust/scx_rustland' ]; then
      mkdir -p /build/source/build/scheds/rust/scx_rustland
      cp -r ${scx-rustland} /build/source/build/scheds/rust/scx_rustland/release
      exit 0
    elif [ ''${3:-} = '--target-dir=scheds/rust/scx_rlfifo' ]; then
      mkdir -p /build/source/build/scheds/rust/scx_rlfifo
      cp -r ${scx-rlfifo} /build/source/build/scheds/rust/scx_rlfifo/release
      exit 0
    elif [ ''${3:-} = '--target-dir=scheds/rust/scx_rusty' ]; then
      mkdir -p /build/source/build/scheds/rust/scx_rusty
      cp -r ${scx-rusty} /build/source/build/scheds/rust/scx_rusty/release
      exit 0
    elif [ ''${3:-} = '--target-dir=rust/scx_stats' ]; then
      mkdir -p /build/source/build/rust/scx_stats
      cp -r ${scx-stats} /build/source/build/rust/scx_stats/release
      exit 0
    elif [ ''${3:-} = '--target-dir=.' ]; then
      exit 0
    fi
    exit 1
  '';

  bpftools_src = fetchFromGitHub {
    owner = "libbpf";
    repo = "bpftool";
    rev = "77a72987353fcae8ce330fd87d4c7afb7677a169";
    hash = "sha256-pItTVewlXgB97AC/WH9rW9J/eYSe2ZdBkJaAgGnDeUU=";
    fetchSubmodules = true;
  };

  fetchBpftool = writeShellScript "fetch_bpftool" ''
    [ "$2" == '${bpftools_src.rev}' ] || exit 1
    cd "$1"
    cp --no-preserve=mode,owner -r "${bpftools_src}/" ./bpftool
  '';

  misbehaviorBash = writeShellScript "bash" ''
    shift 1
    exec "${bash}/bin/bash" "$@"
  '';
in
llvmPackages.stdenv.mkDerivation {
  pname = "scx";
  inherit (scx-common) src version;

  postPatch = ''
    rm meson-scripts/fetch_bpftool
    patchShebangs ./meson-scripts
    cp ${fetchBpftool} meson-scripts/fetch_bpftool
    substituteInPlace meson.build \
      --replace-fail '[build_bpftool' "['${misbehaviorBash}', build_bpftool"
  '';

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    llvmPackages.clang
    fakeCargo
    jq
  ] ++ bpftools_full.buildInputs ++ bpftools_full.nativeBuildInputs;

  buildInputs = [
    elfutils
    zlib
    libbpf_git
  ];

  mesonFlags = [
    "-Dsystemd=disabled"
    "-Dopenrc=disabled"
    "-Dlibbpf_a=disabled"
    "-Dlibalpm=disabled"
  ];

  enableParallelBuilding = true;
  dontStrip = true;
  hardeningDisable = [
    "stackprotector"
    "zerocallusedregs"
  ];

  passthru = {
    inherit scx-common scx-rusty scx-lavd scx-layered scx-rlfifo scx-rustland;
  };

  meta = with lib; {
    homepage = "https://bit.ly/scx_slack";
    description = "sched_ext schedulers and tools";
    license = licenses.gpl2Only;
    platforms = platforms.linux;
    maintainers = with maintainers; [ pedrohlc ];
  };
}
