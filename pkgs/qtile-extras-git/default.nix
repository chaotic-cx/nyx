{ final
, gitOverride
, prev
, ...
}:

gitOverride {
  newInputs = with final; {
    qtile = qtile-module_git;
  };
  nyxKey = "qtile-extras_git";
  prev = prev.python311Packages.qtile-extras;

  versionNyxPath = "pkgs/qtile-extras-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "elParaguayo";
    repo = "qtile-extras";
  };
}
