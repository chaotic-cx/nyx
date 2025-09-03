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
})
