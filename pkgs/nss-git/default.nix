{ final, prev, gitOverride, ... }:

gitOverride {
  nyxKey = "nss_git";
  versionNyxPath = "pkgs/nss-git/version.json";
  versionLocalPath = ./version.json;
  prev = prev.nss_latest;
  fetcher =
    _prevAttrs: finalArgs: final.fetchFromGitHub ({
      owner = "nss-dev";
      repo = "nss";
    } // finalArgs);
  fetchLatestRev = src: final.callPackage ../../shared/github-rev-fetcher.nix { inherit src; ref = "master"; };
  postOverrides = [
    (prevAttrs: {
      # they could have used "sourceRoot"...
      postUnpack = ''
        mkdir _nss
        mv source/* _nss/
        mv _nss source/nss
      '';
    })
  ];
}
