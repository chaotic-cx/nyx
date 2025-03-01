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
        revertZed25516 =
          final.fetchpatch2 {
            url = "https://github.com/zed-industries/zed/commit/17a483cb0319d3454e9528ad1de3e3c5a7cd4d51.patch";
            hash = "sha256-isf/QNzpRCxKdTrZDIQMWcZFnmv/0LsG7se53cj1Plo=";
            revert = true;
          };
        revertZed25209 =
          final.fetchpatch2 {
            url = "https://github.com/zed-industries/zed/commit/1087e05da49bc788f1df81e0aa26ac66c3c73789.patch";
            hash = "sha256-pihAhFQHKNr9LCw1REWAG9WR/WK5z47vh07+iHT264k=";
            revert = true;
          };
      in
      [ revertZed25516 revertZed25209 ] ++ prevAttrs.patches;
    nativeBuildInputs = prevAttrs.nativeBuildInputs ++ [ final.clang ];
    # Nothing wrong on it, just saving compilation time for me!
    dontCheck = true;
    doInstallCheck = false;
  };
})
