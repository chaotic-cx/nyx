{ bpftools
, makeLinuxHeaders
, llvmPackages
, libcap
, linux_6_8
, kernel ? linux_6_8
}:

(bpftools.override {
  linuxHeaders =
    # Bumps to bpftools v7.4.0
    makeLinuxHeaders {
      inherit (kernel) src version patches;
    };
  # Enables "clang-bpf-co-re" feature
  inherit (llvmPackages) stdenv;
}).overrideAttrs (prevAttrs: {
  buildInputs = prevAttrs.buildInputs ++ [
    # Enables "llvm" feature
    llvmPackages.llvm
    # Enables "libcap" feature
    libcap
  ];
})
