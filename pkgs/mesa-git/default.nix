{ directx-headers, final, inputs, nyxUtils, prev, ... }:

(prev.mesa.override {
  inherit directx-headers;
}).overrideAttrs (pa: {
  version = builtins.substring 0 (builtins.stringLength pa.version) inputs.mesa-git-src.rev;
  src = inputs.mesa-git-src;
  buildInputs = pa.buildInputs ++ (with final; [ libunwind lm_sensors ]);
  mesonFlags =
    pa.mesonFlags ++ [
      "-Dandroid-libbacktrace=disabled"
    ];
  patches =
    (nyxUtils.removeByBaseName
      "disk_cache-include-dri-driver-path-in-cache-key.patch"
      pa.patches
    ) ++ [ ./disk_cache-include-dri-driver-path-in-cache-key.patch ];
})
