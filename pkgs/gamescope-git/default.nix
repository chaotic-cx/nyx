{ final, flakes, nyxUtils, prev, ... }:

prev.gamescope.overrideAttrs (pa: {
  version = nyxUtils.gitToVersion flakes.gamescope-git-src;
  src = flakes.gamescope-git-src;
  patches = [ (final.lib.lists.take 1 pa.patches) ];
  buildInputs = pa.buildInputs ++ (with final; [ glm gbenchmark ]);
})
