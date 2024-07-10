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
  pname = "scx-rlfifo";

  inherit (scx-common) src version;
  cargoRoot = "scheds/rust/scx_rlfifo";

  cargoLock.lockFile = ./Cargo.lock;

  nativeBuildInputs = [ pkg-config llvmPackages.clang ];
  buildInputs = [ elfutils zlib ];

  hardeningDisable = [
    "zerocallusedregs"
  ];

  LIBCLANG_PATH = "${llvmPackages.libclang.lib}/lib";

  postPatch = ''
    ln -s ${./Cargo.lock} scheds/rust/scx_rlfifo/Cargo.lock
  '';

  # Can't use sourceRoot because it will fail with lack of permissions in scx_utils
  preBuild = ''
    cd scheds/rust/scx_rlfifo
  '';

  installPhase = ''
    runHook preInstall

    mkdir $out
    cp target/${stdenv.targetPlatform.config}/release/scx_rlfifo $out/

    runHook postInstall
  '';

  enableParallelBuilding = true;
  dontStrip = true;
  dontPatchELF = true;

  meta = with lib; {
    homepage = "https://bit.ly/scx_slack";
    description = "sched_ext schedulers and tools (scx_rlfifo portion)";
    license = licenses.gpl2Only;
    platforms = platforms.linux;
    maintainers = with maintainers; [ pedrohlc ];
  };
}
