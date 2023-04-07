{ lib, writeTextFile, all-packages }:
let
  packageToStore = n: v:
    if lib.attrsets.isDerivation v then
      builtins.toString v
    else lib.trivial.warn "${n} is not a derivation" n;
in
writeTextFile {
  name = "chaotic-nyx-pkgs.txt";
  text = lib.strings.concatStringsSep "\n"
    (lib.attrsets.mapAttrsToList packageToStore all-packages);
}
