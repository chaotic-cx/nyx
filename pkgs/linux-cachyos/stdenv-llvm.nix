{ llvmPackages_latest
, patchelf
, overrideCC
}:
# https://github.com/oluceps/nyx/blob/43941a1cd70f282597611e7fe6c82f90e584f570/pkgs/linux-cachyos/kernel.nix#L19
# https://github.com/xddxdd/nur-packages/blob/94451913d7b86b8bb43d7e914cf76da8b7edf507/pkgs/lantian-linux-xanmod/helpers.nix#L10
let
  noBintools = {
    bootBintools = null;
    bootBintoolsNoLibc = null;
  };
  hostLLVM = llvmPackages_latest.override noBintools;
  buildLLVM = llvmPackages_latest.override noBintools;

  mkLLVMPlatform = platform:
    platform
    // {
      linux-kernel =
        platform.linux-kernel
        // {
          makeFlags =
            (platform.linux-kernel.makeFlags or [ ])
            ++ [
              "LLVM=1"
              "LLVM_IAS=1"
              "CC=${buildLLVM.clangUseLLVM}/bin/clang"
              "LD=${buildLLVM.lld}/bin/ld.lld"
              "HOSTLD=${hostLLVM.lld}/bin/ld.lld"
              "AR=${buildLLVM.llvm}/bin/llvm-ar"
              "HOSTAR=${hostLLVM.llvm}/bin/llvm-ar"
              "NM=${buildLLVM.llvm}/bin/llvm-nm"
              "STRIP=${buildLLVM.llvm}/bin/llvm-strip"
              "OBJCOPY=${buildLLVM.llvm}/bin/llvm-objcopy"
              "OBJDUMP=${buildLLVM.llvm}/bin/llvm-objdump"
              "READELF=${buildLLVM.llvm}/bin/llvm-readelf"
              "HOSTCC=${hostLLVM.clangUseLLVM}/bin/clang"
              "HOSTCXX=${hostLLVM.clangUseLLVM}/bin/clang++"
            ];
        };
    };

  stdenv' = overrideCC hostLLVM.stdenv hostLLVM.clangUseLLVM;
in
stdenv'.override (old: {
  hostPlatform = mkLLVMPlatform old.hostPlatform;
  buildPlatform = mkLLVMPlatform old.buildPlatform;
  extraNativeBuildInputs = [ hostLLVM.lld patchelf ];
})
