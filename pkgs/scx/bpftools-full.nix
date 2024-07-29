{ bpftools
, makeLinuxHeaders
, llvmPackages
, libcap
, linux_latest
, kernel ? linux_latest
}:

(bpftools.override {
  linuxHeaders =
    # Bumps to newer bpftools
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
