{ final, prev, gitOverride, ... }:

gitOverride {
  newInputs = with final; {
    # I hope I don't go to robot-hell bc of this:
    callPackage = file: args:
      let realCall = callPackage file args; in
      if builtins.baseNameOf file == "tg_owt.nix" then
        tg-owt_git
      else
        realCall;
  };

  nyxKey = "telegram-desktop_git";
  prev = prev.telegram-desktop;

  versionNyxPath = "pkgs/telegram-desktop-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "telegramdesktop";
    repo = "tdesktop";
    fetchSubmodules = true;
  };
  ref = "dev";
}
