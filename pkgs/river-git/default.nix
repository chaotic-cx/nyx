{ flakes
, nyxUtils
, prev
, ...
}:

prev.river.overrideAttrs (_prevAttrs: rec {
  version = nyxUtils.gitToVersion src;
  src = flakes.river-git-src;
})
