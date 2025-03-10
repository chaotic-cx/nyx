{ scx
, scx-common
}:

scx.cscheds.overrideAttrs {
  inherit (scx-common) version src patches bpftools_src libbpf_src;
}
