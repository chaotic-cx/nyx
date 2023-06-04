{ enableXWayland ? true
, final
, inputs
, nyxUtils
, prev
, ...
}:

(prev.wlroots_0_16.override {
  inherit enableXWayland;
}).overrideAttrs (pa: {
  version = nyxUtils.gitToVersion inputs.wlroots-git-src;
  src = inputs.wlroots-git-src;
  buildInputs = pa.buildInputs ++ (with final; [ hwdata libdisplay-info ]);
  postPatch = "";
})
