{ final, prev, gitOverride, nyxUtils, ... }:

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

  postOverride = prevAttrs: {
    buildInputs = prevAttrs.buildInputs ++ (with final; [ kf6coreaddons_git ]);
    patches = nyxUtils.removeByURL
      "https://github.com/desktop-app/lib_base/commit/5ca91dbb811c84591780236abc31431e313faf39.patch"
      prevAttrs.patches;
    # postFixup = ''
    #   qtWrapperArgs+=(
    #     --prefix LD_LIBRARY_PATH : "${final.glib_git.out}/lib"
    #   )
    #  '' + prevAttrs.postFixup;
  };
}
