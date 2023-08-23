{ flakes, nyxUtils, prev, ... }:

prev.gamescope.overrideAttrs (_pa: {
  version = nyxUtils.gitToVersion flakes.gamescope-git-src;
  src = flakes.gamescope-git-src;
})
