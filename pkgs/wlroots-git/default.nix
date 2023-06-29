{ enableXWayland ? true
, final
, flakes
, nyxUtils
, prev
, ...
}:

(prev.wlroots_0_16.override {
  inherit enableXWayland;
}).overrideAttrs (pa: {
  version = nyxUtils.gitToVersion flakes.wlroots-git-src;
  src = flakes.wlroots-git-src;
  buildInputs = pa.buildInputs ++ (with final; [ hwdata libdisplay-info ]);
  postPatch = "";
})
