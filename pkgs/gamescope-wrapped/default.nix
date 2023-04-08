{stdenvNoCC, lib, gamescope, gamescopeArgs, gamescopeEnv, makeBinaryWrapper }:

let
  argToWrapper =
    (x: "--add-flags \"${lib.strings.escapeShellArg x}\"");
  args = lib.strings.concatStringsSep " "
    (lib.lists.map argToWrapper gamescopeArgs);
  envToWrapper =
    (k: v: "--set \"${k}\" \"${lib.strings.escapeShellArg v}\"");
  env = lib.strings.concatStringsSep " "
    (lib.attrsets.mapAttrsToList envToWrapper gamescopeEnv);
in
stdenvNoCC.mkDerivation {
  name = "gamescope-wrapped";
  nativeBuildInputs = [makeBinaryWrapper];

  src = gamescope;
  dontBuild = true;

  installPhase = ''
    install -d $out/bin
    makeBinaryWrapper "$src/bin/gamescope" $out/bin/gamescope \
      ${args} \
      ${env}
    # We need the vulkan layers in systemPackages
    ln -s $src/share $out/share
  '';
}
