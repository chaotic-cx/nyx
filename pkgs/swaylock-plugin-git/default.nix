{ final
, flakes
, nyxUtils
, ...
}:

final.swaylock.overrideAttrs (_prevAttrs: {
  pname = "swaylock-plugin";
  version = nyxUtils.gitToVersion flakes.swaylock-plugin-git-src;
  src = flakes.swaylock-plugin-git-src;
})
