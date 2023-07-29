{ flakes
, nyxUtils
, prev
, ...
}:

prev.river.overrideAttrs (_: rec {
  version = nyxUtils.gitToVersion src;
  src = flakes.river-git-src;
})
