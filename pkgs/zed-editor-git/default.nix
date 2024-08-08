{ final, prev, gitOverride, zedPins, rustPlatform_latest, ... }:

gitOverride {
  nyxKey = "zed-editor_git";
  prev = prev.zed-editor;

  newInputs = {
    rustPlatform = rustPlatform_latest;
  };

  versionNyxPath = "pkgs/zed-editor-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "zed-industries";
    repo = "zed";
    fetchSubmodules = true;
  };
  ref = "main";

  withCargoDeps = final.rustPlatform.importCargoLock {
    lockFile = ./Cargo.lock;
    outputHashes = zedPins;
  };

  postOverride = prevAttrs: {
    env = prevAttrs.env // { OPENSSL_NO_VENDOR = 1; };
    RUSTFLAGS = "-Clink-arg=-z -Clink-arg=nostart-stop-gc " + prevAttrs.RUSTFLAGS;
    # pull ahead nixpkgs#317564
    nativeBuildInputs = with final; [ clang ] ++ prevAttrs.nativeBuildInputs;
    postInstall = ''
      install -D ${prevAttrs.src}/crates/zed/resources/app-icon@2x.png $out/share/icons/hicolor/1024x1024@2x/apps/zed.png
      install -D ${prevAttrs.src}/crates/zed/resources/app-icon.png $out/share/icons/hicolor/512x512/apps/zed.png

      # extracted from https://github.com/zed-industries/zed/blob/v0.141.2/script/bundle-linux
      (
        export DO_STARTUP_NOTIFY="true"
        export APP_CLI="zed"
        export APP_ICON="zed"
        export APP_NAME="Zed"
        mkdir -p "$out/share/applications"
        ${with final; lib.getExe envsubst} < "crates/zed/resources/zed.desktop.in" > "$out/share/applications/zed.desktop"
      )
    '';
  };
}
