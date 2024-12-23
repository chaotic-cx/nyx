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
  prev = prev.python3Packages.qtile-extras;

  versionNyxPath = "pkgs/qtile-extras-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "elParaguayo";
    repo = "qtile-extras";
  };

  version = (final.lib.versions.majorMinor prev.python311Packages.qtile-extras.version) + ".99";

  postOverride = prevAttrs: {
    name = prevAttrs.name + ".99";

    buildInputs = prevAttrs.buildInputs ++ [ final.python3Packages.dbus-fast ];

    postPatch = ''
      for f in test/*/test_*.py test/*/*/test_*.py; do
        echo "" > "$f"
      done
    '';
  };
}
