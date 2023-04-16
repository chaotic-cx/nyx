{ enableXWayland ? true
, hwdata
, lib
, libdisplay-info
, nyxUtils
, wayland_next
, wlroots_0_16
, wlroots-git-src
}:
(wlroots_0_16.override {
  inherit enableXWayland;
  wayland = wayland_next;
}).overrideAttrs (pa: {
  version = nyxUtils.gitToVersion wlroots-git-src;
  src = wlroots-git-src;
  buildInputs = pa.buildInputs ++ [ hwdata libdisplay-info ];
  postPatch = "";
})
