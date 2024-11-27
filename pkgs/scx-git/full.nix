{ lib
, final
, scx
}:
final.scx_git.cscheds.overrideAttrs (oldAttrs: {
  inherit (scx.full) pname meta;

  postInstall =
    (oldAttrs.postInstall or "")
    + ''
      cp ${final.scx_git.rustscheds}/bin/* ${placeholder "bin"}/bin/
    '';

  passthru.updateScript = ./update.sh;
})
