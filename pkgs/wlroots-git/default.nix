{ enableXWayland ? true
, final
, flakes
, nyxUtils
, prev
, ...
}:

nyxUtils.multiOverride prev.wlroots_0_16 { inherit enableXWayland; }
  (prevAttrs: {
    version = nyxUtils.gitToVersion flakes.wlroots-git-src;
    src = flakes.wlroots-git-src // { meta.homepage = "https://gitlab.freedesktop.org/wlroots/wlroots/"; inherit (flakes.wlroots-git-src) rev; };
    buildInputs = pa.buildInputs ++ (with final; [ hwdata libdisplay-info ]);
    postPatch = "";
  })
