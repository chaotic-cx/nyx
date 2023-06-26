{ final, inputs, nyxUtils, prev, gbmDriver ? false, gbmBackend ? "dri", ... }:

prev.mesa.overrideAttrs (pa: {
  version = builtins.substring 0 (builtins.stringLength pa.version) inputs.mesa-git-src.rev;
  src = inputs.mesa-git-src;
  buildInputs = pa.buildInputs ++ (with final; [ libunwind lm_sensors ]);
  mesonFlags =
    (builtins.map
      (builtins.replaceStrings [ "virtio-experimental" ] [ "virtio" ])
      pa.mesonFlags
    ) ++ [
      "-Dandroid-libbacktrace=disabled"
    ];
  patches =
    (nyxUtils.removeByBaseName
      "disk_cache-include-dri-driver-path-in-cache-key.patch"
      pa.patches
    ) ++ [ ./disk_cache-include-dri-driver-path-in-cache-key.patch ];
  # expose gbm backend and rename vendor (if necessary)
  outputs =
    if gbmDriver
    then pa.outputs ++ [ "gbm" ]
    else pa.outputs;
  postPatch =
    if gbmBackend != "dri" then pa.postPatch + ''
      sed -i"" 's/"dri"/"bleeding"/' src/gbm/backends/dri/gbm_dri.c src/gbm/main/backend.c
    '' else pa.postPatch;
  postInstall =
    if gbmDriver then pa.postInstall + ''
      mkdir -p $gbm/lib/gbm
      ln -s $out/lib/libgbm.so $gbm/lib/gbm/${gbmBackend}_gbm.so
    '' else pa.postInstall;
  passthru = pa.passthru // {
    inherit gbmBackend;
  };
})
