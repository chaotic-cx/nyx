{
  scx,
  scx-common,
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

  postPatch = builtins.replaceStrings [ "--replace-fail" ] [ "--replace-warn" ] prevAttrs.postPatch;

  mesonFlags = lib.lists.remove "-Dlibalpm=disabled" (lib.flatten prevAttrs.mesonFlags);
})
