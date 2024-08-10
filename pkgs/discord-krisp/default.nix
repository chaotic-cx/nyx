{ prev, ... }:
let
  # krisp-patcher.py courtesy of https://github.com/sersorrel/sys
  patch-krisp = prev.writers.writePython3 "krisp-patcher" {
    libraries = with prev.python3Packages; [ capstone pyelftools ];
    # Ignore syntax checker error codes that affect krisp-patcher.py
    flakeIgnore = [
      "E501"
      "F403"
      "F405"
    ];
  } (builtins.readFile ./krisp-patcher.py);
  binaryName = "Discord";
  node_module="\\$HOME/.config/discord/${prev.discord.version}/modules/discord_krisp/discord_krisp.node";
in
prev.discord.overrideAttrs (previousAttrs: {
  postInstall = previousAttrs.postInstall + ''
    wrapProgramShell $out/opt/${binaryName}/${binaryName} \
    --run "${patch-krisp} ${node_module}"
  '';
  passthru = removeAttrs previousAttrs.passthru [ "updateScript" ];
  meta = {
    nyx.bypassLicense = true;
  } // previousAttrs.meta;
})
