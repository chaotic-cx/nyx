{ directx-headers_next
, lib
, libunwind
, lm_sensors
, mesa
, mesa-git-src
, utils
}:
(mesa.override {
  directx-headers = directx-headers_next;
}).overrideAttrs (fa: {
  version = "23.1.99";
  src = mesa-git-src;
  buildInputs = fa.buildInputs ++ [ libunwind lm_sensors ];
  mesonFlags =
    lib.lists.remove "-Dgallium-rusticl=true" fa.mesonFlags # fails to find "valgrind.h"
    ++ [ "-Dandroid-libbacktrace=disabled" ];
  patches = utils.dropN 2 fa.patches ++ [ ./disk_cache-include-dri-driver-path-in-cache-key.patch ];
})
