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
    # Nothing wrong on it, just saving compilation time for me!
    dontCheck = true;
    # https://github.com/zed-industries/zed/issues/15902
    RUSTFLAGS = "-Clink-arg=-z -Clink-arg=nostart-stop-gc " + prevAttrs.RUSTFLAGS;
    # Starting zed-editor from zed seems to loose these libraries somehow
    nativeBuildInputs = with final; [ makeWrapper cmake ] ++ prevAttrs.nativeBuildInputs;
    postInstall = with final; ''
      wrapProgram $out/bin/zeditor \
        --prefix LD_PRELOAD : ${alsa-lib}/lib/libasound.so.2 \
        --prefix LD_PRELOAD : ${zstd.out}/lib/libzstd.so.1 \
        --prefix LD_PRELOAD : ${openssl.out}/lib/libssl.so.3 \
        --prefix LD_PRELOAD : ${openssl.out}/lib/libcrypto.so.3 \
        --prefix LD_PRELOAD : ${zlib}/lib/libz.so.1 \
        --prefix LD_PRELOAD : ${xorg.libxcb}/lib/libxcb.so.1 \
        --prefix LD_PRELOAD : ${libxkbcommon}/lib/libxkbcommon.so.0 \
        --prefix LD_PRELOAD : ${libxkbcommon}/lib/libxkbcommon-x11.so.0 \
        --prefix LD_PRELOAD : ${curl.out}/lib/libcurl.so.4 \
        --prefix LD_PRELOAD : ${libgit2.lib}/lib/libgit2.so.1.8
    '';
  };
}
