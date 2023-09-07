{ final, prev, gitOverride, ... }:

gitOverride {
  nyxKey = "input-leap_git";
  versionNyxPath = "pkgs/input-leap-git/version.json";
  versionLocalPath = ./version.json;
  prev = prev.input-leap;
  fetcher =
    _prevAttrs: finalArgs: final.fetchFromGitHub ({
      owner = "input-leap";
      repo = "input-leap";
    } // finalArgs);
  fetchLatestRev = src: final.callPackage ../../shared/github-rev-fetcher.nix { inherit src; ref = "master"; };

  postOverrides = [
    (prevAttrs: {
      nativeBuildInputs = prevAttrs.nativeBuildInputs ++ (with final; [
        gtest
        ghc_filesystem
      ]);
      buildInputs = prevAttrs.buildInputs ++ (with final; [
        libuuid
      ]);
      cmakeFlags = [
        "-DINPUTLEAP_USE_EXTERNAL_GTEST=ON"
      ];
    })
  ];
}
