{ final, flakes, nyxUtils, prev, gbmDriver ? false, gbmBackend ? "dri_git", meson ? final.meson, ... }:

nyxUtils.multiOverride prev.mesa { inherit meson; } (prevAttrs: {
  version = builtins.substring 0 (builtins.stringLength prevAttrs.version) flakes.mesa-git-src.rev;
  src = flakes.mesa-git-src;
  buildInputs = prevAttrs.buildInputs ++ (with final; [ libunwind lm_sensors ]);
  mesonFlags =
    (builtins.map
      (builtins.replaceStrings [ "virtio-experimental" ] [ "virtio" ])
      prevAttrs.mesonFlags
    ) ++ [
      "-Dandroid-libbacktrace=disabled"
    ];
  patches =
    (nyxUtils.removeByBaseName
      "disk_cache-include-dri-driver-path-in-cache-key.patch"
      prevAttrs.patches
    ) ++ [
      ./disk_cache-include-dri-driver-path-in-cache-key.patch
      ./gbm-backend.patch
      (# temporary workaround, please remove it later
        # issue: https://gitlab.freedesktop.org/mesa/mesa/-/issues/9692
        # pr: https://gitlab.freedesktop.org/mesa/mesa/-/merge_requests/24888
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
  };
})
