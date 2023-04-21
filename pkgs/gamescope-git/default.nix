{ final, inputs, nyxUtils, prev, ... }:

prev.gamescope.overrideAttrs (pa: {
  version = nyxUtils.gitToVersion inputs.gamescope-git-src;
  src = inputs.gamescope-git-src;
  patches = [ (final.lib.lists.take 1 pa.patches) ];
})
