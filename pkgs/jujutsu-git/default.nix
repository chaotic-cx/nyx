{ prev, gitOverride, ... }:

gitOverride {
  nyxKey = "jujutsu_git";
  prev = prev.jujutsu;

  versionNyxPath = "pkgs/jujutsu-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "jj-vcs";
    repo = "jj";
  };

  preOverride = _prevAttrs: {
    cargoPatches = [ ];
    patches = [ ];
  };
  postOverride = prevAttrs: {
    doCheck = false;
    dontVersionCheck = true;
    env = prevAttrs.env // {
      LIBGIT2_NO_VENDOR = "0";
    };
  };
}
