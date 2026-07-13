{
  final,
  prev,
  gitOverride,
  ...
}:

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

  versionNyxPath = "pkgs/telegram-desktop-git/version.json";
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
    ];
  };
}
