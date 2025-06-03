{
  scx,
  scx-common,
  protobuf,
  libseccomp,
  llvmPackages,
}:

scx.cscheds.overrideAttrs (prevAttrs: {
  inherit (scx-common)
    version
    src
    patches
    bpftools_src
    libbpf_src
    ;
  # These are checked within meson here, but I think they're only used in rustscheds
  nativeBuildInputs = prevAttrs.nativeBuildInputs ++ [
    protobuf
    llvmPackages.libllvm
  ];
  buildInputs = prevAttrs.buildInputs ++ [ libseccomp ];
})
