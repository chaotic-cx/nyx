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
    postPatch = prevAttrs.postPatch + ''
      (cd Telegram/ThirdParty/libprisma && \
        patch -p1 < ${final.fetchpatch {
          url = "https://github.com/desktop-app/libprisma/commit/b9a1ed1a1918b700eb3d140f5047f4f7533421c2.patch";
          hash = "sha256-3mFQipw7ZH8Usj/38bnXtmVNaGuXrI4VRs8FQ7wbUoI=";
        }} \
      )
    '';
    postFixup = ''
      qtWrapperArgs+=(
        --prefix LD_LIBRARY_PATH : "${final.glib_git.out}/lib"
      )
    '' + prevAttrs.postFixup;
  };
}
