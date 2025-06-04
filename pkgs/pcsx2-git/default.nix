{
  flakes,
  final,
  prev,
  gitOverride,
  ...
}:

gitOverride {
  nyxKey = "pcsx2_git";
  prev = prev.pcsx2;

  newInputs = with final; {
    SDL2 = sdl3;
  };

  versionNyxPath = "pkgs/pcsx2-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "PCSX2";
    repo = "pcsx2";
  };
  ref = "master";

  postOverride = prevAttrs: {
    buildInputs =
      prevAttrs.buildInputs
      ++ (
        with final;
        let
          kddockwidgets_qt6 =
            (kdePackages.callPackage "${flakes.nixpkgs}/pkgs/development/libraries/kddockwidgets/default.nix" {
              qtquickcontrols2 = null;
              qtx11extras = null;
            }).overrideAttrs
              (_prevAttrs: {
                cmakeFlags = [
                  "-DKDDockWidgets_FRONTENDS='qtwidgets;qtquick'"
                  "-DKDDockWidgets_QT6=true"
                ];
              });

          plutosvg_ = plutosvg.overrideAttrs (prevAttrs: {
            postInstall =
              (prevAttrs.postInstall or "")
              + ''
                substituteInPlace $out/lib/cmake/plutosvg/plutosvgTargets.cmake \
                  --replace-fail "\''${_IMPORT_PREFIX}/include/" "$dev/include/"
              '';
          });
        in
        [
          kddockwidgets_qt6
          plutovg
          plutosvg_
        ]
      );
  };
}
