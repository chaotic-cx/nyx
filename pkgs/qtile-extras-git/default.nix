{ final
, gitOverride
, prev
, ...
}:

gitOverride {
  newInputs = with final; {
    qtile = qtile-module_git;
    stravalib = python311Packages.stravalib.override {
      pydantic = python311Packages.pydantic_1.overrideAttrs (_prevAttrs: rec {
        version = "1.10.9";

        src = fetchFromGitHub {
          owner = "pydantic";
          repo = "pydantic";
          rev = "refs/tags/v${version}";
          hash = "sha256-POqMxBJUFFS1TnO9h5W7jYwFlukBOng0zbtq4kzmMB4=";
        };
      });
    };
  };

  nyxKey = "qtile-extras_git";
  prev = prev.python311Packages.qtile-extras;

  versionNyxPath = "pkgs/qtile-extras-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "elParaguayo";
    repo = "qtile-extras";
  };

  version = prev.python311Packages.qtile-extras.version + ".99";

  postOverride = prevAttrs: {
    name = prevAttrs.name + ".99";

    postPatch = ''
      echo "" > test/widget/test_iwd.py
      echo "" > test/widget/test_groupbox2.py
      echo "" > test/widget/test_strava.py
    '';
  };
}
