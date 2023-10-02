{ prev, ... }:
let
  patch-krisp = prev.writeScript "patch-krisp" ''
    discord_version="${prev.discord.version}"
    file="$HOME/.config/discord/$discord_version/modules/discord_krisp/discord_krisp.node"
    if [ -f "$file" ]; then
    addr=$("${prev.rizin}/bin/rz-find" -x '4881ec00010000' "$file" | head -n1)
    "${prev.rizin}/bin/rizin" -q -w -c "s $addr + 0x30 ; wao nop" "$file"
    fi
  '';
  binaryName = "Discord";
in
prev.discord.overrideAttrs (previousAttrs: {
  postInstall = previousAttrs.postInstall + ''
    wrapProgramShell $out/opt/${binaryName}/${binaryName} \
    --run "${patch-krisp}"
  '';
  meta = {
    nyx.bypassLicense = true;
  };
})
