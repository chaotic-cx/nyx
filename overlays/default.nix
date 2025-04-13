# Conventions:
# - Sort packages in alphabetic order.
# - If the recipe uses `override` or `overrideAttrs`, then use callOverride,
#   otherwise use `final`.
# - Composed names are separated with minus: `lan-mouse`
# - Versions/patches are suffixed with an underline: `mesa_git`, `libei_0_5`, `linux_hdr`

# NOTE:
# - `*_next` packages will be removed once merged into nixpkgs-unstable.

{
  flakes,
  nixpkgs ? flakes.nixpkgs,
  self ? flakes.self,
  selfOverlay ? self.overlays.default,
  jovian ? flakes.jovian or null,
  fenix ? flakes.fenix or null,
  nixpkgsExtraConfig ? { },
}:
final: prev:

let
  # Required to load version files.
  inherit (final.lib.trivial) importJSON;

  # Our utilities/helpers.
  nyxUtils = import ../shared/utils.nix {
    inherit (final) lib;
    nyxOverlay = selfOverlay;
  };
  inherit (nyxUtils) multiOverride overrideDescription drvDropUpdateScript;

  # Helps when calling .nix that will override packages.
  callOverride =
    path: attrs:
    import path (
      {
        inherit
          final
          flakes
          nyxUtils
          prev
          gitOverride
          rustPlatform_latest
          ;
      }
      // attrs
    );

  # Helps when calling .nix that will override i686-packages.
  callOverride32 =
    path: attrs:
    import path (
      {
        inherit flakes nyxUtils gitOverride;
        final = final.pkgsi686Linux;
        final64 = final;
        prev = prev.pkgsi686Linux;
      }
      // attrs
    );

  # Magic helper for _git packages.
  gitOverride = import ../shared/git-override.nix {
    inherit (final)
      lib
      callPackage
      fetchFromGitHub
      fetchFromGitLab
      ;
    inherit (final.rustPlatform) fetchCargoVendor;
    nyx = self;
    fetchRevFromGitHub = final.callPackage ../shared/github-rev-fetcher.nix { };
    fetchRevFromGitLab = final.callPackage ../shared/gitlab-rev-fetcher.nix { };
  };

  # Latest rust toolchain from Fenix
  rustPlatform_latest =
    if (fenix == null) then
      final.rustPlatform
    else
      let
        inherit (fenix.packages.${final.system}.latest) toolchain;
      in
      final.makeRustPlatform {
        cargo = toolchain;
        rustc = toolchain;
      };

  # Too much variations
  cachyosPackages = callOverride ../pkgs/linux-cachyos { };

  # Microarch stuff
  makeMicroarchPkgs = import ../shared/make-microarch.nix {
    inherit
      nixpkgs
      final
      selfOverlay
      nixpkgsExtraConfig
      ;
  };

  # Common stuff for scx-schedulers
  scx-common = final.callPackage ../pkgs/scx-git/common.nix { };

  # Required for 32-bit packages
  has32 = final.stdenv.hostPlatform.isLinux && final.stdenv.hostPlatform.isx86;

  # Required for kernel packages
  inherit (final.stdenv) isLinux;

  # Apply Jovian overlay only on x86_64-linux
  jovian-chaotic =
    if final.stdenv.hostPlatform.isLinux && final.stdenv.hostPlatform.isx86_64 then
      {
        inherit (jovian.legacyPackages.x86_64-linux) linux_jovian mesa-radv-jupiter mesa-radeonsi-jupiter;
        recurseForDerivations = true;
      }
    else
      { };
in
{
  inherit nyxUtils jovian-chaotic;

  nyx-generic-git-update = final.callPackage ../pkgs/nyx-generic-git-update { };

  alacritty_git = callOverride ../pkgs/alacritty-git { };

  ananicy-rules-cachyos_git = callOverride ../pkgs/ananicy-cpp-rules { };

  applet-window-title = final.callPackage ../pkgs/applet-window-title { };

  appmenu-gtk3-module = final.callPackage ../pkgs/appmenu-gtk3-module { };

  beautyline-icons = final.callPackage ../pkgs/beautyline-icons { };

  bpftools_full =
    if isLinux then
      final.callPackage ../pkgs/bpftools-full { }
    else
      throw "No bpftools for your target";

  busybox_appletless = multiOverride prev.busybox { enableAppletSymlinks = false; } (
    overrideDescription (old: old + " (without applets' symlinks)")
  );

  bytecode-viewer_git = final.callPackage ../pkgs/bytecode-viewer-git { };

  conduwuit_git = final.callPackage ../pkgs/conduwuit-git {
    rustPlatform = rustPlatform_latest;
  };

  discord-krisp = callOverride ../pkgs/discord-krisp { };

  distrobox_git = callOverride ../pkgs/distrobox-git { };

  dr460nized-kde-theme = final.callPackage ../pkgs/dr460nized-kde-theme { };

  fetchTorGit = callOverride ../pkgs/fetchtorgit { };

  firedragon-unwrapped = final.callPackage ../pkgs/firedragon { };

  firedragon = final.wrapFirefox final.firedragon-unwrapped {
    inherit (final.firedragon-unwrapped) extraPrefsFiles extraPoliciesFiles;
    libName = "firedragon";
  };

  firefox-unwrapped_nightly = final.callPackage ../pkgs/firefox-nightly { };
  firefox_nightly = final.wrapFirefox final.firefox-unwrapped_nightly {
    nameSuffix = "-nightly";
    wmClass = "firefox-nightly";
    icon = "firefox-nightly";
  };

  gamescope_git = callOverride ../pkgs/gamescope-git { };
  gamescope-wsi_git = callOverride ../pkgs/gamescope-git { isWSI = true; };
  gamescope-wsi32_git =
    if has32 then
      callOverride32 ../pkgs/gamescope-git { isWSI = true; }
    else
      throw "No gamescope-wsi32_git for non-x86";

  jujutsu_git = callOverride ../pkgs/jujutsu-git { };

  lan-mouse_git = callOverride ../pkgs/lan-mouse-git { };

  latencyflex-vulkan = final.callPackage ../pkgs/latencyflex-vulkan { };

  libbpf_git = callOverride ../pkgs/libbpf-git { };

  libdrm_git = callOverride ../pkgs/libdrm-git { };
  libdrm32_git =
    if has32 then callOverride32 ../pkgs/libdrm-git { } else throw "No libdrm32_git for non-x86";

  libportal_git = callOverride ../pkgs/libportal-git { };

  linux_cachyos = drvDropUpdateScript cachyosPackages.cachyos.kernel;
  linux_cachyos-hardened = drvDropUpdateScript cachyosPackages.cachyos-rc.kernel;
  linux_cachyos-rc = cachyosPackages.cachyos-rc.kernel;
  linux_cachyos-server = drvDropUpdateScript cachyosPackages.cachyos-server.kernel;

  linuxPackages_cachyos = cachyosPackages.cachyos;
  linuxPackages_cachyos-hardened = cachyosPackages.cachyos-hardened;
  linuxPackages_cachyos-lto = cachyosPackages.cachyos-lto;
  linuxPackages_cachyos-rc = cachyosPackages.cachyos-rc;
  linuxPackages_cachyos-server = cachyosPackages.cachyos-server;

  luxtorpeda = final.callPackage ../pkgs/luxtorpeda {
    luxtorpedaVersion = importJSON ../pkgs/luxtorpeda/version.json;
  };

  # You should not need "mangohud32_git" since it's embedded in "mangohud_git"
  mangohud_git = callOverride ../pkgs/mangohud-git { };
  mangohud32_git =
    if has32 then callOverride32 ../pkgs/mangohud-git { } else throw "No mangohud32_git for non-x86";

  mesa_git = callOverride ../pkgs/mesa-git { };
  mesa32_git =
    if has32 then callOverride32 ../pkgs/mesa-git { } else throw "No mesa32_git for non-x86";

  mpv-vapoursynth =
    (final.mpv-unwrapped.wrapper {
      mpv = final.mpv-unwrapped.override {
        vapoursynthSupport = true;
        vapoursynth = final.vapoursynth.withPlugins [ final.vapoursynth-mvtools ];
      };
    }).overrideAttrs
      (overrideDescription (old: old + " (includes vapoursynth-mvtools)"));

  niri_git = callOverride ../pkgs/niri-git {
    niriPins = importJSON ../pkgs/niri-git/pins.json;
  };

  nix-top_abandoned = final.callPackage ../pkgs/nix-top { };

  nordvpn = final.callPackage ../pkgs/nordvpn { };

  nut_git = callOverride ../pkgs/nut-git { };

  nss_git = callOverride ../pkgs/nss-git { };

  openmohaa = final.callPackage ../pkgs/openmohaa {
    openmohaaVersion = importJSON ../pkgs/openmohaa/version.json;
  };
  openmohaa_git = callOverride ../pkgs/openmohaa-git { };

  openrgb_git = final.callPackage ../pkgs/openrgb-git { };

  openvr_git = callOverride ../pkgs/openvr-git { };

  owl-wlr_git = callOverride ../pkgs/owl-git { };

  pkgsx86_64_v2 = final.pkgsAMD64Microarchs.x86-64-v2;
  pkgsx86_64_v3 = final.pkgsAMD64Microarchs.x86-64-v3;
  pkgsx86_64_v4 = final.pkgsAMD64Microarchs.x86-64-v4;

  pkgsAMD64Microarchs = builtins.mapAttrs (arch: _inferiors: makeMicroarchPkgs "x86_64" arch) (
    builtins.removeAttrs final.lib.systems.architectures.inferiors [
      "default"
      "armv5te"
      "armv6"
      "armv7-a"
      "armv8-a"
      "mips32"
      "loongson2f"
    ]
  );

  proton-ge-custom = final.callPackage ../pkgs/proton-ge-custom {
    protonGeTitle = "Proton-GE";
    protonGeVersions = importJSON ../pkgs/proton-ge-custom/versions.json;
  };

  pwvucontrol_git = callOverride ../pkgs/pwvucontrol-git {
    pwvucontrolPins = importJSON ../pkgs/pwvucontrol-git/pins.json;
  };

  qtile_git = with final; python311Packages.toPythonApplication qtile-module_git;
  qtile-module_git = callOverride ../pkgs/qtile-git { };
  qtile-extras_git = callOverride ../pkgs/qtile-extras-git { };

  river_git = callOverride ../pkgs/river-git { };

  sdl_git = callOverride ../pkgs/sdl-git { };

  spirv-headers_git = callOverride ../pkgs/spirv-headers-git { };

  scx_git = {
    cscheds = final.callPackage ../pkgs/scx-git/cscheds.nix { inherit scx-common; };
    rustscheds = final.callPackage ../pkgs/scx-git/rustscheds.nix { inherit scx-common final; };
    full = final.callPackage ../pkgs/scx-git/full.nix { inherit final; };
    recurseForDerivations = true;
  };

  scx-full_git = drvDropUpdateScript final.scx_git.full;

  sway-unwrapped_git = callOverride ../pkgs/sway-unwrapped-git { };
  sway_git = prev.sway.override {
    sway-unwrapped = final.sway-unwrapped_git;
  };

  swaylock-plugin_git = callOverride ../pkgs/swaylock-plugin-git { };

  telegram-desktop-unwrapped_git = callOverride ../pkgs/telegram-desktop-git { };
  telegram-desktop_git = final.telegram-desktop.override {
    unwrapped = final.telegram-desktop-unwrapped_git;
  };
  tg-owt_git = callOverride ../pkgs/tg-owt-git { };

  torzu_git = final.kdePackages.callPackage ../pkgs/torzu-git {
    current = importJSON ../pkgs/torzu-git/version.json;
    inherit (final) fetchTorGit;
  };

  vulkanPackages_latest = callOverride ../pkgs/vulkan-versioned {
    vulkanVersions = importJSON ../pkgs/vulkan-versioned/latest.json;
  };

  xdg-desktop-portal-wlr_git = callOverride ../pkgs/portal-wlr-git { };

  wayland_git = callOverride ../pkgs/wayland-git { };
  wayland-protocols_git = callOverride ../pkgs/wayland-protocols-git { };
  wayland-scanner_git = prev.wayland-scanner.overrideAttrs (_: {
    inherit (final.wayland_git) src;
  });

  wlroots_git = callOverride ../pkgs/wlroots-git { };

  yt-dlp_git = callOverride ../pkgs/yt-dlp-git { };

  zed-editor_git = callOverride ../pkgs/zed-editor-git {
    zedPins = importJSON ../pkgs/zed-editor-git/pins.json;
  };
  zed-editor-fhs_git = final.zed-editor_git.fhs;

  zfs_cachyos = cachyosPackages.zfs;

  zon2nix_zig_0_13 = multiOverride prev.zon2nix { zig_0_11 = final.zig_0_13; } (_prevAttrs: {
    src = final.fetchFromGitHub {
      owner = "andreafeletto";
      repo = "zon2nix";
      rev = "5413d1afd430cc175de297fd09f26c2a9beef075";
      hash = "sha256-lgtM6Wu9vh3OxGI5iw7npfh6f9yJIpRh8oJsosxnJiU=";
    };
  });
}
