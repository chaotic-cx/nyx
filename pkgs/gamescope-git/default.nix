{ final, flakes, nyxUtils, prev, ... }:

prev.gamescope.overrideAttrs (pa: {
  version = nyxUtils.gitToVersion flakes.gamescope-git-src;
  src = flakes.gamescope-git-src;
})
