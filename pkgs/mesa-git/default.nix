{ final
, flakes
, nyxUtils
, prev
, gbmDriver ? false
, gbmBackend ? "dri_git"
, meson ? final.meson
, mesaTestAttrs ? final
, ...
}:

nyxUtils.multiOverride prev.mesa { inherit meson; } (prevAttrs: {
  version = builtins.substring 0 (builtins.stringLength prevAttrs.version) flakes.mesa-git-src.rev;
  src = flakes.mesa-git-src;
  buildInputs = prevAttrs.buildInputs ++ (with final; [ libunwind lm_sensors ]);
  mesonFlags =
    (builtins.map
      (builtins.replaceStrings [ "virtio-experimental" ] [ "virtio" ])
      prevAttrs.mesonFlags
    );
  patches =
    (nyxUtils.removeByBaseName
      "disk_cache-include-dri-driver-path-in-cache-key.patch"
      prevAttrs.patches
    ) ++ [
      ./disk_cache-include-dri-driver-path-in-cache-key.patch
      ./gbm-backend.patch
      # issue: https://gitlab.freedesktop.org/mesa/mesa/-/issues/9692
      # temporary workaround, please remove it later
      (# pr: https://gitlab.freedesktop.org/mesa/mesa/-/merge_requests/24885
        final.fetchurl {
          url = "https://gitlab.freedesktop.org/emersion/mesa/-/commit/63003b7bf9cb258042f1ffec98e46c59d29bf0fc.patch";
          hash = "sha256-6GPYh7nsvFhW7OymvJyJsLgKgEsJV0kbtbmzmsHZjoo=";
        })
      (# pr: https://gitlab.freedesktop.org/mesa/mesa/-/merge_requests/24888
        final.fetchurl {
          url = "https://gitlab.freedesktop.org/derekf/mesa/-/commit/e7f24cca359e2b57bb619593478ae2498e27146c.patch";
          hash = "sha256-u4uLDgjnMTlAjrlPUoyDx9ZVgw+Yjv6+r/vm2kyDjWk=";
        })
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
