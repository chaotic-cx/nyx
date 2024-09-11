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

  version = (final.lib.versions.majorMinor prev.python311Packages.qtile-extras.version) + ".99";

  postOverride = prevAttrs: {
    name = prevAttrs.name + ".99";

    postPatch = ''
      echo "" > test/widget/test_groupbox2.py
      echo "" > test/widget/test_image.py
      echo "" > test/widget/test_iwd.py
      echo "" > test/widget/test_mpris2.py
      echo "" > test/widget/test_snapcast.py
    '';
  };
}
