{ prev, ... }:
let
  # krisp-patcher.py courtesy of https://github.com/sersorrel/sys
  krispPatcher = prev.writers.writePython3 "krisp-patcher" {
    libraries = with prev.python3Packages; [
      capstone
      pyelftools
    ];
    # Ignore syntax checker error codes that affect krisp-patcher.py
    flakeIgnore = [
      "E501"
      "F403"
      "F405"
    ];
  } (builtins.readFile ./krisp-patcher.py);
  binaryName = "Discord";
  nodeModule = "\\$HOME/.config/discord/${prev.discord.version}/modules/discord_krisp/discord_krisp.node";

  unwrappedPatched = prev.discord.unwrappedDiscord.overrideAttrs (previousAttrs: {
    postInstall = previousAttrs.postInstall + ''
      wrapProgramShell $out/opt/${binaryName}/${binaryName} \
      --run "${krispPatcher} ${nodeModule}"
    '';
    passthru = removeAttrs previousAttrs.passthru [ "updateScript" ];
    meta = {
      nyx.bypassLicense = true;
    }
    // previousAttrs.meta;
  });
in
prev.discord.override {
  unwrappedDiscord = unwrappedPatched;
}
