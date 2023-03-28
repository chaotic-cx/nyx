{ gamescope, gamescope-git-src, lib }:
gamescope.overrideAttrs (pa: {
  version = "3.11.52-unstable";
  src = gamescope-git-src;
  patches = [ (lib.lists.take 1 pa.patches) ];
})
