{ final, ... }:

let
  # CachyOS repeating stuff.
  mainVersions = final.lib.trivial.importJSON ./versions.json;

  mkCachyKernel = attrs: final.callPackage ./make.nix
    ({ versions = mainVersions; } // attrs);
in
{
  inherit mainVersions mkCachyKernel;

  cachyos = mkCachyKernel {
    taste = "linux-cachyos";
    configPath = ./config-nix/cachyos.x86_64-linux.nix;
  };

  cachyos-sched-ext = mkCachyKernel {
    taste = "linux-cachyos-sched-ext";
    configPath = ./config-nix/cachyos-sched-ext.x86_64-linux.nix;
    cpuSched = "sched-ext";
    description = "Linux SCHED-EXT with BORE scheduler Kernel by CachyOS with other patches and improvements";
  };

  cachyos-server = mkCachyKernel {
    taste = "linux-cachyos-server";
    configPath = ./config-nix/cachyos-server.x86_64-linux.nix;
    basicCachy = false;
    cpuSched = "eevdf";
    ticksHz = 300;
    tickRate = "idle";
    preempt = "server";
    hugePages = "madvise";
    withDAMON = true;
    description = "Linux EEVDF scheduler Kernel by CachyOS targeted for Servers";
  };

  cachyos-hardened = mkCachyKernel {
    taste = "archive/linux-cachyos-hardened";
    configPath = ./config-nix/cachyos-hardened.x86_64-linux.nix;
    cpuSched = "hardened";
    versions = mainVersions // {
      linux = with final.linux_6_5; {
        inherit version;
        hash = src.outputHash;
      };
    };
  };
}
