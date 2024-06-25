{pkgs, system, legacyPackages}:

let
  cleanPackages = import ./remove-non-derivations.nix legacyPackages;

  warn =
    pkgs.lib.warn "chaotic-nyx: for a better experience, replace 'chaotic.packages' with 'chaotic.legacyPackages'.";
in
if system != "x86_64-linux" then
  warn (import ./remove-cross-stuff.nix cleanPackages)
else
  warn cleanPackages
