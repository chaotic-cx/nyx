{ prev, gitOverride, ... }:

gitOverride {
  nyxKey = "nixfmt_rfc166";
  prev = prev.nixfmt;

  versionNyxPath = "pkgs/nixfmt-rfc166/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "piegamesde";
    repo = "nixfmt";
    fetchSubmodules = true;
  };
  ref = "rfc101-style";
}
