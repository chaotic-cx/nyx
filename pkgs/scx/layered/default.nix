{ stdenv
, lib
, rustPlatform
, pkg-config
, elfutils
, zlib
, llvmPackages_16
, scx-common
}:

rustPlatform.buildRustPackage rec {
  pname = "scx-layered";

  inherit (scx-common) src version;
  cargoRoot = "scheds/rust-user/scx_layered";

  cargoLock.lockFile = ./Cargo.lock;

  nativeBuildInputs = [ pkg-config llvmPackages_16.clang ];
  buildInputs = [ elfutils zlib ];
  LIBCLANG_PATH = "${llvmPackages_16.libclang.lib}/lib";

  postPatch = ''
    ln -s ${./Cargo.lock} scheds/rust-user/scx_layered/Cargo.lock
  '';

  # Can't use sourceRoot because it will fail with lack of permissions in scx_utils
  preBuild = ''
    cd scheds/rust-user/scx_layered
  '';

  installPhase = ''
    runHook preInstall

    mkdir $out
    cp target/${stdenv.targetPlatform.config}/release/scx_layered $out/

    runHook postInstall
  '';

  enableParallelBuilding = true;
  dontStrip = true;
  dontPatchELF = true;

  meta = with lib; {
    homepage = "https://bit.ly/scx_slack";
    description = "sched_ext schedulers and tools (scx_layered portion)";
    license = licenses.gpl2Only;
    platforms = platforms.linux;
    maintainers = with maintainers; [ pedrohlc ];
  };
}
