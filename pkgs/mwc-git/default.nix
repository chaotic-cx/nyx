{
  final,
  gitOverride,
  ...
}:

let
  stable = final.callPackage ./package.nix { };
in
gitOverride {
  nyxKey = "mwc_git";
  prev = stable;

  versionNyxPath = "pkgs/mwc-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "dqrk0jeste";
    repo = "mwc";
    fetchSubmodules = true;
  };

  extraPassthru = {
    inherit stable;
  };
}
