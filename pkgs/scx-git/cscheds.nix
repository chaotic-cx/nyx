{
  scx,
  scx-common,
  bash,
  lib,
}:

scx.cscheds.overrideAttrs (prevAttrs: {
  inherit (scx-common)
    version
    src
    patches
    bpftools_src
    libbpf_src
    ;

  postPatch =
    builtins.replaceStrings [ "--replace-fail" "substituteInPlace" ] [ "#" "#" ] prevAttrs.postPatch
    + ''
      substituteInPlace ./meson-scripts/build_bpftool --replace-fail '#!/bin/bash' '#!${bash}/bin/bash'
    '';

  mesonFlags = lib.lists.remove "-Dlibalpm=disabled" (lib.flatten prevAttrs.mesonFlags);
})
