{ flakes
, nyxUtils
, prev
, ...
}:
prev.river.overrideAttrs (prevAttrs: rec {
  version = nyxUtils.gitToVersion src;
  src = flakes.river-git-src;
})
