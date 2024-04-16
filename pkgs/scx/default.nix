{ lib
, llvmPackages
, writeShellScriptBin
, scx-common
, scx-rusty
, scx-lavd
, scx-layered
, scx-rlfifo
, scx-rustland
, pkg-config
, meson
, ninja
, bpftools_full
, elfutils
, zlib
, libbpf_git
, jq
}:

let
  fakeCargo = writeShellScriptBin "cargo" ''
    set -e
    if [ ''${3:-} = '--target-dir=rust/scx_utils' ]; then
      exit 0
    elif [ ''${3:-} = '--target-dir=rust/scx_rustland_core' ]; then
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
    fi
    exit 1
  '';
in
llvmPackages.stdenv.mkDerivation {
  pname = "scx";
  inherit (scx-common) src version;

  postPatch = ''
    cp -r ${scx-rusty} ./scheds/rust/scx_rusty/release
    cp -r ${scx-layered} ./scheds/rust/scx_layered/release
    cp -r ${scx-lavd} ./scheds/rust/scx_lavd/release
    cp -r ${scx-rlfifo} ./scheds/rust/scx_rlfifo/release
    cp -r ${scx-rustland} ./scheds/rust/scx_rustland/release
    patchShebangs ./meson-scripts
  '';

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    llvmPackages.clang
    fakeCargo
    bpftools_full
    jq
  ];

  buildInputs = [
    elfutils
    zlib
    libbpf_git
  ];

  mesonFlags = [
    "-Dsystemd=disabled"
    "-Dopenrc=disabled"
    "-Dbpftool=disabled"
    "-Dlibbpf_a=disabled"
  ];

  enableParallelBuilding = true;
  dontStrip = true;
  hardeningDisable = [ "stackprotector" ];

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
