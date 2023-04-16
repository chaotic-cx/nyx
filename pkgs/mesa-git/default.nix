{ directx-headers_next
, lib
, libunwind
, lm_sensors
, mesa
, mesa-git-src
, nyxUtils
}:
(mesa.override {
  directx-headers = directx-headers_next;
}).overrideAttrs (fa: {
  version = builtins.substring 0 (builtins.stringLength fa.version) mesa-git-src.rev;
  src = mesa-git-src;
  buildInputs = fa.buildInputs ++ [ libunwind lm_sensors ];
  mesonFlags =
    lib.lists.remove "-Dgallium-rusticl=true" fa.mesonFlags # fails to find "valgrind.h"
    ++ [ "-Dandroid-libbacktrace=disabled" ];
  patches = nyxUtils.dropN 2 fa.patches ++ [ ./disk_cache-include-dri-driver-path-in-cache-key.patch ];
})
