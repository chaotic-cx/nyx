{ inputs, nyxUtils, prev, ... }:

prev.mangohud.overrideAttrs (prevAttrs: rec {
  version = nyxUtils.gitToVersion src;
  src = inputs.mangohud-git-src;
  patches = [ ./preload-nix-workaround.patch ] ++
    (nyxUtils.removeByBaseName "preload-nix-workaround.patch" prevAttrs.patches);
})
