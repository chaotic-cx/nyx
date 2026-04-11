{
  final,
  gitOverride,
  prev,
  flakes,
  ...
}:

gitOverride {
  nyxKey = "qtile-module_git";
  prev = prev.python3Packages.qtile;

  versionNyxPath = "pkgs/qtile-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "qtile";
    repo = "qtile";
  };
  ref = "master";

  version = prev.python3Packages.qtile.version + ".99";

  postOverride = prevAttrs: {
    name = prevAttrs.name + ".99";
    patches = [ ];
    postPatch = "";
    disabledTests = (prevAttrs.disabledTests or [ ]) ++ [
      # fork in multi-threaded parent causes child deadlock
      "test_stepping_between_groups_should_skip_scratchpads"
    ];
    passthru = prevAttrs.passthru // {
      tests.smoke-test = import ./test.nix {
        inherit (flakes) nixpkgs;
        chaotic = flakes.self;
      } final;
    };
  };
}
