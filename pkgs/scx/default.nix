{ lib
, llvmPackages_16
, rustPlatform
, writeShellScriptBin
, scx-common
, scx-rusty
, scx-layered
, pkg-config
, meson
, ninja
, cargo
, bpftools
, elfutils
, zlib
, libbpf
}:

let
  fakeCargo = writeShellScriptBin "cargo" ''
    set -e
    if [ ''${3:-} = '--target-dir=rust/scx_utils' ]; then
      exit 0
    elif [ ''${3:-} = '--target-dir=scheds/rust-user/scx_layered' ]; then
      mkdir -p /build/source/build/scheds/rust-user/scx_layered
      cp -r ${scx-layered} /build/source/build/scheds/rust-user/scx_layered/release
      exit 0
    elif [ ''${3:-} = '--target-dir=scheds/rust-user/scx_rusty' ]; then
      mkdir -p /build/source/build/scheds/rust-user/scx_rusty
      cp -r ${scx-rusty} /build/source/build/scheds/rust-user/scx_rusty/release
      exit 0
    fi
    exit 1
  '';
in
llvmPackages_16.stdenv.mkDerivation {
  pname = "scx";
  inherit (scx-common) src version;

  postPatch = ''
    cp -r ${scx-rusty} ./scheds/rust-user/scx_rusty/release
    cp -r ${scx-layered} ./scheds/rust-user/scx_layered/release
    patchShebangs ./meson-scripts
  '';

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    llvmPackages_16.clang
    fakeCargo
    bpftools
  ];

  buildInputs = [
    elfutils
    zlib
    libbpf
  ];

  enableParallelBuilding = true;
  dontStrip = true;

  meta = with lib; {
    homepage = "https://bit.ly/scx_slack";
    description = "sched_ext schedulers and tools";
    license = licenses.gpl2Only;
    platforms = platforms.linux;
    maintainers = with maintainers; [ pedrohlc ];
  };
}
