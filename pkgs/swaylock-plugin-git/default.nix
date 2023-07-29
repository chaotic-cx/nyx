{ final
, flakes
, nyxUtils
, prev
, ...
}:

final.swaylock.overrideAttrs (_: {
  pname = "swaylock-plugin";
  version = nyxUtils.gitToVersion flakes.swaylock-plugin-git-src;
  src = flakes.swaylock-plugin-git-src;
})
