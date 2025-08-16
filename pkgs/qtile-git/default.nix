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
    pypaBuildFlags =
      with final;
      map (x: "--config-setting=${x}") [
        "PANGO_PATH=${pango.out}/lib/libpango-1.0.so.0"
        "PANGOCAIRO_PATH=${pango.out}/lib/libpangocairo-1.0.so.0"
        "GOBJECT_PATH=${glib.out}/lib/libgobject-2.0.so.0"
        "XCBCURSOR_PATH=${xorg.xcbutilcursor.out}/lib/libxcb-cursor.so.0"
      ];
    env =
      (prevAttrs.env or { })
      // (with final; {
        QTILE_PIXMAN_PATH = "${lib.getDev pixman}/include";
        QTILE_LIBDRM_PATH = "${lib.getDev libdrm}/include/libdrm";
      });
    passthru = prevAttrs.passthru // {
      tests.smoke-test = import ./test.nix {
        inherit (flakes) nixpkgs;
        chaotic = flakes.self;
      } final;
    };
  };
}
