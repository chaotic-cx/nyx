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

  newInputs = {
    wlroots = final.wlroots_0_20;
  };

  manifestPath = "pkgs/qtile-git/manifest.json";
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
    doCheck = false;
    postInstall = ''
      install resources/qtile.desktop -Dt $out/share/xsessions
      install resources/qtile.desktop -Dt $out/share/wayland-sessions
    '';
    passthru = prevAttrs.passthru // {
      tests.smoke-test = import ./test.nix {
        inherit (flakes) nixpkgs;
        chaotic = flakes.self;
      } final;
    };
  };
}
