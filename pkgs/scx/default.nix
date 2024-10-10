{ lib
, llvmPackages
, writeShellScript
, writeShellScriptBin
, fetchFromGitHub
, scx-common
, scx-bpfland
, scx-lavd
, scx-layered
, scx-mitosis
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
  # grep 'bpftool_commit =' ./meson.build
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
    "-Doffline=true"
    "-Denable_rust=false"
  ];

  enableParallelBuilding = true;
  dontStrip = true;
  hardeningDisable = [
    "stackprotector"
    "zerocallusedregs"
  ];

  # These two are borken right now:
  # cp ${scx-mitosis}/scx_mitosis $out/bin/
  # cp ${scx-rusty}/scx_rusty $out/bin/
  # cp ${scx-stats}/libscx_stats* $out/lib/
  postInstall = ''
    cp ${scx-bpfland}/scx_bpfland $out/bin/
    cp ${scx-lavd}/scx_lavd $out/bin/
    cp ${scx-layered}/scx_layered $out/bin/
    cp ${scx-rlfifo}/scx_rlfifo $out/bin/
    cp ${scx-rustland}/scx_rustland $out/bin/
  '';

  passthru = {
    inherit scx-common scx-bpfland scx-lavd scx-layered scx-mitosis scx-rlfifo scx-rustland scx-rusty scx-stats;
  };

  meta = with lib; {
    homepage = "https://bit.ly/scx_slack";
    description = "sched_ext schedulers and tools";
    license = licenses.gpl2Only;
    platforms = platforms.linux;
    maintainers = with maintainers; [ pedrohlc ];
  };
}
