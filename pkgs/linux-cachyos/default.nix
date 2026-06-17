{
  final,
  ...
}@inputs:

let
  inherit (final.stdenv) isx86_64 isLinux;
  inherit (final.lib.trivial) importJSON;

  # CachyOS repeating stuff.
  mainVersions = importJSON ./versions.json;
  hardenedVersions = importJSON ./versions-hardened.json;
  ltsVersions = importJSON ./versions-lts.json;
  rcVersions = importJSON ./versions-rc.json;
  serverVersions = importJSON ./versions-server.json;
  hardenedVars = importJSON ./config-vars/cachyos-hardened.json;
  ltoVars = importJSON ./config-vars/cachyos-lto.json;
  ltsVars = importJSON ./config-vars/cachyos-lts.json;
  rcVars = importJSON ./config-vars/cachyos-rc.json;
  serverVars = importJSON ./config-vars/cachyos-server.json;

  ltoKernelAttrs = {
    taste = "linux-cachyos";
    configPath = ./config-nix/cachyos-lto.x86_64-linux.nix;
    cachyVars = ltoVars;

    inherit (import ./lib/llvm-pkgs.nix inputs) callPackage;
    stdenv = final.clangStdenv;

    packagesExtend = import ./lib/llvm-module-overlay.nix inputs;

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

  # Evaluation hack
  brokenReplacement = final.hello.overrideAttrs (prevAttrs: {
    meta = prevAttrs.meta // {
      platform = [ ];
      broken = true;
    };
  });

  isUnsupported = !isx86_64 || !isLinux;

  mkCachyKernel =
    if isUnsupported then
      # Evaluation hack
      _attrs: {
        kernel = brokenReplacement;
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

    # since all flavors use the same versions.json, we just need the updateScript in one of them
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

    withHDR = false;

    description = "Linux EEVDF scheduler Kernel by CachyOS targeted for Servers";

    packagesExtend = preventBuildingKernelModules;
  };

  cachyos-hardened = mkCachyKernel {
    taste = "linux-cachyos-hardened";
    configPath = ./config-nix/cachyos-hardened.x86_64-linux.nix;
    cachyVars = hardenedVars;

    versions = hardenedVersions;
    withUpdateScript = "hardened";

    withHDR = false;

    packagesExtend = preventBuildingKernelModules;
  };

  zfs = final.zfs_2_4.overrideAttrs (prevAttrs: {
    src = if isUnsupported then brokenReplacement else gccKernel.zfs_cachyos.src;
    patches = [ ];
    passthru = prevAttrs.passthru // {
      kernelModuleAttribute = "zfs_cachyos";
    };
    postPatch = builtins.replaceStrings [ "grep --quiet '^Linux-M" ] [ "# " ] prevAttrs.postPatch;
  });
}
