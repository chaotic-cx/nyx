{ final
, gitOverride
, prev
, flakes
, ...
}:

gitOverride {
  nyxKey = "qtile-module_git";
  prev = prev.python311Packages.qtile;

  versionNyxPath = "pkgs/qtile-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "qtile";
    repo = "qtile";
  };
  ref = "master";

  postOverride = prevAttrs: {
    passthru = prevAttrs.passthru // {
      tests.smoke-test = import ./test.nix
        {
          inherit (flakes) nixpkgs;
          chaotic = flakes.self;
        }
        final;
    };
  };
}
