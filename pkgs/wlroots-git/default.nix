{ enableXWayland ? true
, hwdata
, lib
, libdisplay-info
, wayland_next
, wlroots_0_16
, wlroots-git-src
}:
(wlroots_0_16.override {
  inherit enableXWayland;
  wayland = wayland_next;
}).overrideAttrs (pa: {
  version = "0.17-unstable";
  src = wlroots-git-src;
  buildInputs = pa.buildInputs ++ [ hwdata libdisplay-info ];
  postPatch = "";
})
