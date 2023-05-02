{ final
, inputs
, nyxUtils
, prev
, wayland
, ...
}:

(prev.sway-unwrapped.override {
  wlroots_0_16 = final.wlroots_git;
  inherit wayland;
}).overrideAttrs (prevAttrs: rec {
  version = nyxUtils.gitToVersion src;
  src = inputs.sway-git-src;
  patches =
    nyxUtils.removeByURL
      "https://github.com/swaywm/sway/commit/dee032d0a0ecd958c902b88302dc59703d703c7f.diff"
      prevAttrs.patches;
})
