{
  scx,
  scx-common,
}:

scx.cscheds.overrideAttrs (_prevAttrs: {
  inherit (scx-common)
    version
    src
    patches
    bpftools_src
    libbpf_src
    ;
  # Cherry-picks nixpkgs#424862
  preInstall = "";
  postFixup = ''
    mkdir -p ${placeholder "dev"}
    cp -r libbpf ${placeholder "dev"}
  '';
})
