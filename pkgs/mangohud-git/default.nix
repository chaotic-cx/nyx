{ inputs, nyxUtils, prev, mangohud32, ... }:

(prev.mangohud.override { inherit mangohud32; }).overrideAttrs (prevAttrs: rec {
  version = nyxUtils.gitToVersion src;
  src = inputs.mangohud-git-src;
  patches = [ ./preload-nix-workaround.patch ] ++
    (nyxUtils.removeByBaseName "preload-nix-workaround.patch" prevAttrs.patches);
})
