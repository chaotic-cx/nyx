{ prev, gitOverride, ... }:

gitOverride {
  nyxKey = "nss_git";
  prev = prev.nss_latest;

  versionNyxPath = "pkgs/nss-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "nss-dev";
    repo = "nss";
  };
  ref = "master";

  postOverride = _prevAttrs: {
    # they could have used "sourceRoot"...
    postUnpack = ''
      mkdir _nss
      mv source/* _nss/
      mv _nss source/nss
    '';
  };
}
