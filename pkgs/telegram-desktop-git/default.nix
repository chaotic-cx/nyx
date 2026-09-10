{
  final,
  prev,
  gitOverride,
  ...
}:

let
  tlottie = final.rustPlatform.buildRustPackage {
    pname = "tlottie";
    version = "unstable";

    src = final.fetchFromGitHub {
      owner = "dkaraush";
      repo = "tlottie";
      rev = "dev";
      hash = "sha256-9FxWiJgdCpLRGHfkPD+4tPnMDf3aVQaNWob1qEAlr+8=";
    };

    cargoHash = "sha256-R/l5zMRB/2/a4Yf6toPBBvJ1SvebWsGeumwW9U6b7So=";

    buildPhase = ''
      runHook preBuild

      cargo rustc \
        --release \
        --features c-api \
        --lib \
        --crate-type staticlib

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      install -Dm644 \
        target/release/libtlottie.a \
        "$out/lib/libtlottie.a"

      install -Dm644 \
        include/tlottie.h \
        "$out/include/tlottie/tlottie.h"

      runHook postInstall
    '';
  };
in
gitOverride {
  newInputs = with final; {
    # I hope I don't go to robot-hell bc of this:
    callPackage =
      file: args:
      let
        realCall = callPackage file args;
      in
      if baseNameOf file == "tg_owt.nix" then tg-owt_git else realCall;
  };

  nyxKey = "telegram-desktop-unwrapped_git";
  prev = prev.telegram-desktop.unwrapped;

  manifestPath = "pkgs/telegram-desktop-git/manifest.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "telegramdesktop";
    repo = "tdesktop";
    fetchSubmodules = true;
  };
  ref = "dev";

  postOverride = prevAttrs: {
    patches = [ ];

    # AssertIsDebug() is only available in _DEBUG builds, define it away
    env = (prevAttrs.env or { }) // {
      NIX_CFLAGS_COMPILE = (prevAttrs.env.NIX_CFLAGS_COMPILE or "") + " -DAssertIsDebug(...)=;";
    };

    buildInputs = prevAttrs.buildInputs ++ [
      final.tde2e_git
      final.minizip
      final.pango
      tlottie
    ];
  };
}
