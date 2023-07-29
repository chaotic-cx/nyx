{ final
, flakes
, nyxUtils
, prev
, ...
}:

nyxUtils.multiOverride prev.sway-unwrapped { wlroots = final.wlroots_git; }
  (prevAttrs: rec {
    version = nyxUtils.gitToVersion src;
    src = flakes.sway-git-src;
    patches =
      nyxUtils.removeByURL
        "https://github.com/swaywm/sway/commit/dee032d0a0ecd958c902b88302dc59703d703c7f.diff"
        prevAttrs.patches;
  })
