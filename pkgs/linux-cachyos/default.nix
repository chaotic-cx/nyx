{
  final,
  ...
}@inputs:

let
  inherit (final.stdenv.hostPlatform) isx86_64 isLinux;
  inherit (final.lib.trivial) importJSON;

  # CachyOS repeating stuff.
  mainVersions = importJSON ./manifest.json;
  boreVars = importJSON ./config-vars/cachyos-bore.json;
  boreVersions = importJSON ./manifest-bore.json;
  hardenedVars = importJSON ./config-vars/cachyos-hardened.json;
  hardenedVersions = importJSON ./manifest-hardened.json;
  ltoVars = importJSON ./config-vars/cachyos-lto.json;
  ltsVars = importJSON ./config-vars/cachyos-lts.json;
  ltsVersions = importJSON ./manifest-lts.json;
  rcVars = importJSON ./config-vars/cachyos-rc.json;
  rcVersions = importJSON ./manifest-rc.json;
  serverVars = importJSON ./config-vars/cachyos-server.json;
  serverVersions = importJSON ./manifest-server.json;

  # Clang/LTO things
  pkgsLLVM = import ./lib/llvm-pkgs.nix inputs;

  ltoKernelAttrs = {
    taste = "linux-cachyos";
    configPath = ./config-nix/cachyos-lto.x86_64-linux.nix;
    cachyVars = ltoVars;

    inherit (pkgsLLVM) callPackage;
    stdenv = pkgsLLVM.clangStdenv;

    zfsOverride = {
      inherit (final)
        autoreconfHook269
        util-linux
        coreutils
        perl
        udevCheckHook
        zlib
        libuuid
        python3
        attr
        openssl
        libtirpc
        nfs-utils
        gawk
        gnugrep
        gnused
        systemd
        smartmontools
        sysstat
        pkg-config
        curl
        pam
        nix-update-script
        ;
    };

    description = "Linux EEVDF-BORE scheduler Kernel by CachyOS built with LLVM and Thin LTO";
  };

  isUnsupported = !isx86_64 || !isLinux;

  mkCachyKernel =
    if isUnsupported then
      _attrs: {
        kernel = throw "Cachyos kernels are not supported on this system";
        recurseForDerivations = false;
      }
    else
      {
        callPackage ? final.callPackage,
        ...
      }@attrs:
      callPackage ./packages-for.nix (
        {
          versions = mainVersions;
          inherit inputs;
          cachyOverride = newAttrs: mkCachyKernel (attrs // newAttrs);
        }
        // attrs
      );

  gccKernel = mkCachyKernel {
    taste = "linux-cachyos";
    configPath = ./config-nix/cachyos-gcc.x86_64-linux.nix;

    cachyVars = ltoVars // {
      "_use_llvm_lto" = "none";
    };

    # since all flavors use the same manifest.json, we just need the updateScript in one of them
    withUpdateScript = "stable";
  };

  preventBuildingKernelModules =
    _kernel: _final: prev:
    prev // { recurseForDerivations = false; };
in
{
  inherit
    mainVersions
    rcVersions
    hardenedVersions
    mkCachyKernel
    ;

  cachyos-gcc = gccKernel;

  cachyos-lts = mkCachyKernel {
    taste = "linux-cachyos-lts";
    configPath = ./config-nix/cachyos-lts.x86_64-linux.nix;
    cachyVars = ltsVars;

    versions = ltsVersions;
    withUpdateScript = "lts";

    packagesExtend = preventBuildingKernelModules;
  };

  cachyos-bore = mkCachyKernel {
    taste = "linux-cachyos-bore";
    configPath = ./config-nix/cachyos-bore.x86_64-linux.nix;
    cachyVars = boreVars;

    versions = boreVersions;
    withUpdateScript = "bore";

    description = "Linux EEVDF scheduler Kernel by CachyOS with BORE scheduler";

    packagesExtend = preventBuildingKernelModules;
  };

  cachyos-rc = mkCachyKernel (
    ltoKernelAttrs
    // {
      taste = "linux-cachyos-rc";
      configPath = ./config-nix/cachyos-rc.x86_64-linux.nix;
      cachyVars = rcVars;

      versions = rcVersions;
      withUpdateScript = "rc";

      packagesExtend = preventBuildingKernelModules;
    }
  );

  cachyos-lto = mkCachyKernel ltoKernelAttrs;

  cachyos-lto-znver4 = mkCachyKernel (
    ltoKernelAttrs
    // {
      configPath = ./config-nix/cachyos-znver4.x86_64-linux.nix;
      cachyVars = ltoVars // {
        _processor_opt = "ZEN4";
      };

      packagesExtend = preventBuildingKernelModules;
    }
  );

  cachyos-server = mkCachyKernel {
    taste = "linux-cachyos-server";
    configPath = ./config-nix/cachyos-server.x86_64-linux.nix;
    cachyVars = serverVars;

    versions = serverVersions;
    withUpdateScript = "server";

    description = "Linux EEVDF scheduler Kernel by CachyOS targeted for Servers";

    packagesExtend = preventBuildingKernelModules;
  };

  cachyos-hardened = mkCachyKernel {
    taste = "linux-cachyos-hardened";
    configPath = ./config-nix/cachyos-hardened.x86_64-linux.nix;
    cachyVars = hardenedVars;

    versions = hardenedVersions;
    withUpdateScript = "hardened";

    packagesExtend = preventBuildingKernelModules;
  };

  zfs =
    if isUnsupported then
      throw "Cachyos ZFS is not supported on this system"
    else
      final.zfs_2_4.overrideAttrs (prevAttrs: {
        src = gccKernel.zfs_cachyos.src;
        patches = [ ];
        passthru = prevAttrs.passthru // {
          kernelModuleAttribute = "zfs_cachyos";
        };
        postPatch = builtins.replaceStrings [ "grep --quiet '^Linux-M" ] [ "# " ] prevAttrs.postPatch;
      });
}
