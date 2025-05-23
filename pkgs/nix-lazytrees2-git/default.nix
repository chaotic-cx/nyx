{ final, ... }:
let
  nixComponents_git = final.nix_git.components.appendPatches [
    (final.fetchpatch {
      url = "https://github.com/NixOS/nix/pull/13225/commits/c98026e982165c1999ff8005450fa83e94464f14.patch";
      hash = "sha256-BcRJOFZ8Z9F91A5QkxkVcBTqNzpRtZKKNGgaZMOIea8=";
    })
  ];

in
nixComponents_git.nix-everything.overrideAttrs (prevAttrs: {
  passthru = prevAttrs.passthru // {
    components = nixComponents_git;
  };
  meta = prevAttrs.meta // {
    description = prevAttrs.meta.description + " (includes edolstra's lazy trees v2)";
  };
})
