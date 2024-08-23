{ stdenv
, lib
, rustPlatform
, scx-common
}:

rustPlatform.buildRustPackage rec {
  pname = "scx-stats";

  inherit (scx-common) src version;
  cargoRoot = "rust/scx_stats";

  cargoLock.lockFile = ./Cargo.lock;

  postPatch = ''
    ln -fs ${./Cargo.lock} rust/scx_stats/Cargo.lock
  '';

  # Can't use sourceRoot because it will fail with lack of permissions in scx_utils
  preBuild = ''
    cd rust/scx_stats
  '';

  installPhase = ''
    runHook preInstall

    mkdir $out
    cp target/${stdenv.targetPlatform.config}/release/libscx_stats* $out/

    runHook postInstall
  '';

  enableParallelBuilding = true;
  dontStrip = true;
  dontPatchELF = true;

  meta = with lib; {
    homepage = "https://bit.ly/scx_slack";
    description = "sched_ext schedulers and tools (scx_stats portion)";
    license = licenses.gpl2Only;
    platforms = platforms.linux;
    maintainers = with maintainers; [ pedrohlc ];
  };
}
