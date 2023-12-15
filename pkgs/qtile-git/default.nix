{ gitOverride
, prev
, ...
}:

final.python311Packages.toPythonApplication (gitOverride {
  nyxKey = "qtile_git";
  prev = prev.python311Packages.qtile;

  versionNyxPath = "pkgs/qtile-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "qtile";
    repo = "qtile";
  };
  ref = "master";
})
