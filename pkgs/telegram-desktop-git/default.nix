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
    glibmm_2_68 = glibmm_git;
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

  postOverride = prevAttrs: {
    buildInputs = prevAttrs.buildInputs ++ (with final; [ kf6coreaddons_git ]);
    postFixup = ''
      qtWrapperArgs+=(
        --prefix LD_LIBRARY_PATH : "${final.glib_git.out}/lib"
      )
    '' + prevAttrs.postFixup;
  };
}
