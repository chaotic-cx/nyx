{ final, prev, gitOverride, ... }:

gitOverride (current: {
  nyxKey = "zed-editor_git";
  prev = prev.zed-editor;

  versionNyxPath = "pkgs/zed-editor-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "zed-industries";
    repo = "zed";
    fetchSubmodules = true;
  };
  ref = "main";

  preOverride = prevAttrs: {
    postPatch = builtins.replaceStrings [ prevAttrs.version ] [ "*" ] prevAttrs.postPatch;
  };

  postOverride = prevAttrs: {
    env = prevAttrs.env // {
      ZED_COMMIT_SHA = current.rev;
    };
    patches =
      let
        revertZed25209 =
          final.fetchpatch2 {
            url = "https://github.com/zed-industries/zed/commit/1087e05da49bc788f1df81e0aa26ac66c3c73789.patch";
            hash = "sha256-pihAhFQHKNr9LCw1REWAG9WR/WK5z47vh07+iHT264k=";
            revert = true;
          };
        revertZed25035 =
          final.fetchpatch2 {
            url = "https://github.com/zed-industries/zed/commit/5eadeb67b0446caf4fbac03282ed031157474eae.patch";
            hash = "sha256-ccu8DLpehC3f4Yw4q9MHAXF5inkzNuap8jW/E4CAZ0Q=";
            revert = true;
          };
        revertZed24996 =
          final.fetchpatch2 {
            url = "https://github.com/zed-industries/zed/commit/bcba0b92ed7842310959f82cc9ee93673c5dba87.patch";
            hash = "sha256-y4EZhZ2KPvOoginx5EfgGBas/PGOLYkhbS0Cvp8rh5g=";
            revert = true;
          };
      in
      [ revertZed25209 revertZed25035 revertZed24996 ] ++ prevAttrs.patches;
    # Nothing wrong on it, just saving compilation time for me!
    dontCheck = true;
    doInstallCheck = false;
  };
})
