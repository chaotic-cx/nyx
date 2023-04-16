{ gamescope, gamescope-git-src, lib, nyxUtils }:
gamescope.overrideAttrs (pa: {
  version = nyxUtils.gitToVersion gamescope-git-src;
  src = gamescope-git-src;
  patches = [ (lib.lists.take 1 pa.patches) ];
})
