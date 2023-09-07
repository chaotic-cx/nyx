{ final
, flakes
, nyxUtils
, prev
, gitOverride
, gbmDriver ? false
, gbmBackend ? "dri_git"
, meson ? final.meson
, mesaTestAttrs ? final
, ...
}:

let
  current = final.lib.trivial.importJSON ./version.json;
in
gitOverride {
  newInputs = { inherit meson; };
  nyxKey = if final.stdenv.is32bit then "mesa32_git" else "mesa_git";
  versionNyxPath = "pkgs/mesa-git/version.json";
  prev = prev.mesa;
  fetcher =
    _prevAttrs: finalArgs: final.fetchFromGitHub ({
      owner = "chaotic-cx";
      repo = "mesa-mirror";
    } // finalArgs);
  fetchLatestRev = src: final.callPackage ../../shared/github-rev-fetcher.nix { inherit src; ref = "main"; };
  withUpdateScript = !final.stdenv.is32bit;
  version = builtins.substring 0 (builtins.stringLength prev.mesa.version) current.rev;
  inherit current;

  postOverrides = [
    (prevAttrs: {
      buildInputs = prevAttrs.buildInputs ++ (with final; [ libunwind lm_sensors ]);
      mesonFlags =
        builtins.map
          (builtins.replaceStrings [ "virtio-experimental" ] [ "virtio" ])
          prevAttrs.mesonFlags;
      patches =
        (nyxUtils.removeByBaseName
          "disk_cache-include-dri-driver-path-in-cache-key.patch"
          prevAttrs.patches
        ) ++ [
          ./disk_cache-include-dri-driver-path-in-cache-key.patch
          ./gbm-backend.patch
        ];
      # expose gbm backend and rename vendor (if necessary)
      outputs =
        if gbmDriver
        then prevAttrs.outputs ++ [ "gbm" ]
        else prevAttrs.outputs;
      postPatch =
        if gbmBackend != "dri_git" then prevAttrs.postPatch + ''
          sed -i"" 's/"dri_git"/"${gbmBackend}"/' src/gbm/backends/dri/gbm_dri.c src/gbm/main/backend.c
        '' else prevAttrs.postPatch;
      postInstall =
        if gbmDriver then prevAttrs.postInstall + ''
          mkdir -p $gbm/lib/gbm
          ln -s $out/lib/libgbm.so $gbm/lib/gbm/${gbmBackend}_gbm.so
        '' else prevAttrs.postInstall;
      passthru = prevAttrs.passthru // {
        inherit gbmBackend;
        tests.smoke-test = import ./test.nix
          {
            inherit (flakes) nixpkgs;
            chaotic = flakes.self;
          }
          mesaTestAttrs;
      };
    })
  ];
}
