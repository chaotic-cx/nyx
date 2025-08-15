{
  scx,
  scx-common,
  nyxUtils,
  lib
}:

scx.cscheds.overrideAttrs (prevAttrs: {
  inherit (scx-common)
    version
    src
    patches
    bpftools_src
    libbpf_src
    ;
  #
  postPatch = builtins.replaceStrings [ "--replace-fail" ] [ "--replace-warn" ] prevAttrs.postPatch;
  # Cherry-picks nixpkgs#424862
  preInstall = "";
  postFixup = ''
    mkdir -p ${placeholder "dev"}
    cp -r libbpf ${placeholder "dev"}
  '';

  mesonFlags = lib.lists.remove "-Dlibalpm=disabled" (lib.flatten prevAttrs.mesonFlags);
})
