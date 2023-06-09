{ inputs
, nyxUtils
, prev
, ...
}:
prev.river.overrideAttrs (prevAttrs: rec {
  version = nyxUtils.gitToVersion src;
  src = inputs.river-git-src;
})
