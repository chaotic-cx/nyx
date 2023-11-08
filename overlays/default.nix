# Conventions:
# - Sort packages in alphabetic order.
# - If the recipe uses `override` or `overrideAttrs`, then use callOverride,
#   otherwise use `final`.
# - Composed names are separated with minus: `input-leap`
# - Versions/patches are suffixed with an underline: `mesa_git`, `libei_0_5`, `linux_hdr`
# - Use `inherit (final) nyxUtils` since someone might want to override our utils

# NOTE:
# - `*_next` packages will be removed once merged into nixpkgs-unstable.

{ flakes, self ? flakes.self, selfOverlay ? self.overlays.default }:
final: prev:
let
  # Required to load version files.
  inherit (final.lib.trivial) importJSON;

  # Our utilities/helpers.
  nyxUtils = import ../shared/utils.nix { inherit (final) lib; nyxOverlay = selfOverlay; };
  inherit (nyxUtils) dropAttrsUpdateScript dropUpdateScript multiOverride multiOverrides overrideDescription;

  # Helps when calling .nix that will override packages.
  callOverride = path: attrs: import path ({ inherit final flakes nyxUtils prev gitOverride; } // attrs);

  # Helps when calling .nix that will override i686-packages.
  callOverride32 = path: attrs: import path ({
    inherit flakes nyxUtils gitOverride;
    final = final.pkgsi686Linux;
    prev = prev.pkgsi686Linux;
  } // attrs);

  # CachyOS repeating stuff.
  cachyVersions = importJSON ../pkgs/linux-cachyos/versions.json;

  # CachyOS repeating stuff.
  cachyZFS = _finalAttrs: prevAttrs:
    let
      zfs = prevAttrs.zfsUnstable.overrideAttrs (prevAttrs: {
        src =
          final.fetchFromGitHub {
            owner = "cachyos";
            repo = "zfs";
            inherit (cachyVersions.zfs) rev hash;
          };
        meta = prevAttrs.meta // { broken = false; };
        patches = [ ];
      });
    in
    {
      kernel_configfile = prevAttrs.kernel.configfile;
      inherit zfs;
      zfsStable = zfs;
      zfsUnstable = zfs;
    };

  # Magic helper for _git packages.
  gitOverride = import ../shared/git-override.nix {
    inherit (final) lib callPackage fetchFromGitHub fetchFromGitLab;
    nyx = self;
    fetchRevFromGitHub = final.callPackage ../shared/github-rev-fetcher.nix { };
    fetchRevFromGitLab = final.callPackage ../shared/gitlab-rev-fetcher.nix { };
  };
in
{
  inherit nyxUtils;

  nyx-generic-git-update = final.callPackage ../pkgs/nyx-generic-git-update { };

  alacritty_git = callOverride ../pkgs/alacritty-git { };

  ananicy-cpp-rules = final.callPackage ../pkgs/ananicy-cpp-rules { };

  applet-window-appmenu = final.libsForQt5.callPackage ../pkgs/applet-window-appmenu { };

  applet-window-title = final.callPackage ../pkgs/applet-window-title { };

  appmenu-gtk3-module = final.callPackage ../pkgs/appmenu-gtk3-module { };

  beautyline-icons = final.callPackage ../pkgs/beautyline-icons { };

  blurredwallpaper = final.callPackage ../pkgs/blurredwallpaper { };

  busybox_appletless = multiOverride
    prev.busybox
    { enableAppletSymlinks = false; }
    (overrideDescription (old: old + " (without applets' symlinks)"));

  bytecode-viewer_git = final.callPackage ../pkgs/bytecode-viewer-git { };

  discord-krisp = callOverride ../pkgs/discord-krisp { };

  dr460nized-kde-theme = final.callPackage ../pkgs/dr460nized-kde-theme { };

  droid-sans-mono-nerdfont = multiOverrides
    final.nerdfonts
    { fonts = [ "DroidSansMono" ]; }
    [
      dropUpdateScript
      (overrideDescription (_prevDesc: "Provides \"DroidSansM Nerd Font\" font family."))
    ];

  extra-cmake-modules_git = callOverride ../pkgs/extra-cmake-modules-git/latest.nix { };

  firedragon-unwrapped = final.callPackage ../pkgs/firedragon { };

  firedragon = final.wrapFirefox final.firedragon-unwrapped {
    inherit (final.firedragon-unwrapped) extraPrefsFiles extraPoliciesFiles;
    libName = "firedragon";
  };

  firefox-unwrapped_nightly = final.callPackage ../pkgs/firefox-nightly { };
  firefox_nightly = final.wrapFirefox final.firefox-unwrapped_nightly { };

  gamescope_git = callOverride ../pkgs/gamescope-git { };

  # Used by telegram-desktop_git
  glib_git = callOverride ../pkgs/glib-git { };
  glibmm_git = callOverride ../pkgs/glibmm-git { };

  input-leap_git = callOverride ../pkgs/input-leap-git {
    inherit (final.libsForQt5.qt5) qttools;
  };

  kf6coreaddons_git = callOverride ../pkgs/kf6coreaddons-git/latest.nix { };

  latencyflex-vulkan = final.callPackage ../pkgs/latencyflex-vulkan { };

  linux_cachyos = final.callPackage ../pkgs/linux-cachyos {
    inherit cachyVersions;
    cachyFlavor = rec {
      taste = "linux-cachyos";
      configfile = final.callPackage ../pkgs/linux-cachyos/configfile-raw.nix {
        inherit cachyVersions;
        cachyTaste = taste;
      };
      config = import ../pkgs/linux-cachyos/config-x86_64-linux.nix;
      baked = final.callPackage ../pkgs/linux-cachyos/configfile-bake.nix {
        inherit configfile;
      };
    };
    kernelPatches = [ ]; # feel free to override.
  };

  linux_cachyos-server = final.callPackage ../pkgs/linux-cachyos {
    inherit cachyVersions;
    cachyFlavor = rec {
      taste = "linux-cachyos-server";
      configfile = final.callPackage ../pkgs/linux-cachyos/configfile-raw.nix {
        inherit cachyVersions;
        cachyTaste = taste;
      };
      config = import ../pkgs/linux-cachyos/config-x86_64-linux-server.nix;
      baked = final.callPackage ../pkgs/linux-cachyos/configfile-bake.nix {
        inherit configfile;
      };
    };
    kernelPatches = [ ]; # feel free to override.
  };

  linux-hardened_cachyos = final.callPackage ../pkgs/linux-cachyos {
    inherit cachyVersions;
    cachyFlavor = rec {
      taste = "archive/linux-cachyos-hardened";
      configfile = final.callPackage ../pkgs/linux-cachyos/configfile-raw.nix {
        inherit cachyVersions;
        cachyTaste = taste;
      };
      config = import ../pkgs/linux-cachyos/config-x86_64-linux-hardened.nix;
      baked = final.callPackage ../pkgs/linux-cachyos/configfile-bake.nix {
        inherit configfile;
      };
    };
    kernelPatches = [ ]; # feel free to override.
  };

  linuxPackages_cachyos = (dropAttrsUpdateScript
    ((final.linuxPackagesFor final.linux_cachyos).extend cachyZFS)
  ) // { _description = "Kernel modules for linux_cachyos"; };

  linuxPackages_cachyos-server = (dropAttrsUpdateScript
    ((final.linuxPackagesFor final.linux_cachyos-server).extend cachyZFS)
  ) // { _description = "Kernel modules for linux_cachyos-server"; };

  linuxPackages-hardened_cachyos = (dropAttrsUpdateScript
    ((final.linuxPackagesFor final.linux-hardened_cachyos).extend cachyZFS)
  ) // { _description = "Kernel modules for linux-hardened_cachyos"; };

  luxtorpeda = final.callPackage ../pkgs/luxtorpeda {
    luxtorpedaVersion = importJSON ../pkgs/luxtorpeda/version.json;
  };

  # You should not need "mangohud32_git" since it's embedded in "mangohud_git"
  mangohud_git = callOverride ../pkgs/mangohud-git { };
  mangohud32_git =
    if final.stdenv.hostPlatform.isLinux && final.stdenv.hostPlatform.isx86
    then
      callOverride32 ../pkgs/mangohud-git { }
    else throw "No mangohud32_git for non-x86";

  mesa_git = callOverride ../pkgs/mesa-git { gbmDriver = true; };
  mesa32_git =
    if final.stdenv.hostPlatform.isLinux && final.stdenv.hostPlatform.isx86
    then
      callOverride32 ../pkgs/mesa-git { }
    else throw "No mesa32_git for non-x86";

  mpv-vapoursynth = (final.wrapMpv
    (final.mpv-unwrapped.override { vapoursynthSupport = true; })
    {
      extraMakeWrapperArgs = [
        "--prefix"
        "LD_LIBRARY_PATH"
        ":"
        "${final.vapoursynth-mvtools}/lib/vapoursynth"
      ];
    }
  ).overrideAttrs (overrideDescription (old: old + " (includes vapoursynth)"));

  nix-flake-schemas_git = callOverride ../pkgs/nix-flake-schemas-git { };

  nordvpn = final.callPackage ../pkgs/nordvpn { };

  nss_git = callOverride ../pkgs/nss-git { };

  openmohaa = final.callPackage ../pkgs/openmohaa {
    openmohaaVersion = importJSON ../pkgs/openmohaa/version.json;
  };
  openmohaa_git = callOverride ../pkgs/openmohaa-git { };

  proton-ge-custom = final.callPackage ../pkgs/proton-ge-custom {
    protonGeTitle = "Proton-GE";
    protonGeVersions = importJSON ../pkgs/proton-ge-custom/versions.json;
  };

  river_git = callOverride ../pkgs/river-git { };

  sway-unwrapped_git = callOverride ../pkgs/sway-unwrapped-git { };
  sway_git = prev.sway.override {
    sway-unwrapped = final.sway-unwrapped_git;
  };

  swaylock-plugin_git = callOverride ../pkgs/swaylock-plugin-git { };

  telegram-desktop_git = callOverride ../pkgs/telegram-desktop-git { };
  tg-owt_git = callOverride ../pkgs/tg-owt-git { };

  # You should not need "mangohud32_git" since it's embedded in "mangohud_git"
  vkshade_git = callOverride ../pkgs/vkshade-git { };
  vkshade32_git =
    if final.stdenv.hostPlatform.isLinux && final.stdenv.hostPlatform.isx86
    then
      callOverride32 ../pkgs/vkshade-git { }
    else throw "No vkshade32_git for non-x86";

  vulkanPackages_latest = callOverride ../pkgs/vulkan-versioned
    { vulkanVersions = importJSON ../pkgs/vulkan-versioned/latest.json; };

  xdg-desktop-portal-wlr_git = callOverride ../pkgs/portal-wlr-git { };

  wayland_git = callOverride ../pkgs/wayland-git { };
  wayland-protocols_git = callOverride ../pkgs/wayland-protocols-git { };
  wayland-scanner_git = final.wayland_git.bin;

  waynergy_git = callOverride ../pkgs/waynergy-git { };

  wlroots_git = callOverride ../pkgs/wlroots-git { };

  yt-dlp_git = callOverride ../pkgs/yt-dlp-git { };

  yuzu-early-access_git = callOverride ../pkgs/yuzu-ea-git { };
}
