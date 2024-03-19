{ stdenv
, lib
, rustPlatform
, pkg-config
, elfutils
, zlib
, llvmPackages
, scx-common
}:

rustPlatform.buildRustPackage rec {
  pname = "scx-lavd";

  inherit (scx-common) src version;
  cargoRoot = "scheds/rust/scx_lavd";

  cargoLock.lockFile = ./Cargo.lock;

  nativeBuildInputs = [ pkg-config llvmPackages.clang ];
  buildInputs = [ elfutils zlib ];
  LIBCLANG_PATH = "${llvmPackages.libclang.lib}/lib";

  postPatch = ''
    ln -s ${./Cargo.lock} scheds/rust/scx_lavd/Cargo.lock
  '';

  # Can't use sourceRoot because it will fail with lack of permissions in scx_utils
  preBuild = ''
    cd scheds/rust/scx_lavd
  '';

  installPhase = ''
    runHook preInstall

    mkdir $out
    cp target/${stdenv.targetPlatform.config}/release/scx_lavd $out/

    runHook postInstall
  '';

  enableParallelBuilding = true;
  dontStrip = true;
  dontPatchELF = true;

  meta = with lib; {
    homepage = "https://bit.ly/scx_slack";
    description = "sched_ext schedulers and tools (scx_lavd portion)";
    license = licenses.gpl2Only;
    platforms = platforms.linux;
    maintainers = with maintainers; [ pedrohlc ];
  };
}
