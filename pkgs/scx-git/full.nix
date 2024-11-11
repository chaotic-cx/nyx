{ lib
, final
, scx
}:
final.scx_git.cscheds.overrideAttrs (oldAttrs: {
  inherit (scx.full) pname meta;

  postInstall =
    (oldAttrs.postInstall or "")
    + ''
      cp ${lib.getExe final.scx_git.bpfland} $out/bin/
      cp ${lib.getExe final.scx_git.lavd} $out/bin/
      cp ${lib.getExe final.scx_git.layered} $out/bin/
      cp ${lib.getExe final.scx_git.rlfifo} $out/bin/
      cp ${lib.getExe final.scx_git.rustland} $out/bin/
      cp ${lib.getExe final.scx_git.rusty} $out/bin/
    '';

  updateScript = ./update.sh;
})
