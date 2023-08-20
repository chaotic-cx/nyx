# Conventions:
# - Sort packages in alphabetic order.
# - If the recipe uses `override` or `overrideAttrs`, then use callOverride,
#   otherwise use `final`.
# - Composed names are separated with minus: `input-leap`
# - Versions/patches are suffixed with an underline: `mesa_git`, `libei_0_5`, `linux_hdr`
# - Use `inherit (final) nyxUtils` since someone might want to override our utils

# NOTE:
# - `*_next` packages will be removed once merged into nixpkgs-unstable.

{ flakes }: final: prev:
let
  # Required to load version files.
  inherit (final.lib.trivial) importJSON;

  # Our utilities/helpers.
  nyxUtils = final.callPackage ../shared/utils.nix { } //
    { _description = "Pack of functions that are useful for Chaotic-Nyx and might become useful for you too"; };
  inherit (nyxUtils) dropAttrsUpdateScript dropUpdateScript multiOverride multiOverrides overrideDescription;

  # Helps when calling .nix that will override packages.
  callOverride = path: attrs: import path ({ inherit final flakes nyxUtils prev; } // attrs);

  # Helps when calling .nix that will override i686-packages.
  callOverride32 = path: attrs: import path ({
    inherit flakes nyxUtils;
    final = final.pkgsi686Linux;
    prev = prev.pkgsi686Linux;
  } // attrs);

  # CachyOS repeating stuff.
  cachyVersions = importJSON ../pkgs/linux-cachyos/versions.json;

  # CachyOS repeating stuff.
  cachyZFS = _: prevAttrs:
    let
      zfs = prevAttrs.zfsUnstable.overrideAttrs (pa: {
        src =
          final.fetchFromGitHub {
            owner = "cachyos";
            repo = "zfs";
            inherit (cachyVersions.zfs) rev hash;
          };
        meta = pa.meta // { broken = false; };
        patches = [ ];
      });
    in
    {
      kernel_configfile = prevAttrs.kernel.configfile;
      inherit zfs;
      zfsStable = zfs;
      zfsUnstable = zfs;
    };
in
{
  inherit nyxUtils;

  alacritty_git = callOverride ../pkgs/alacritty-git {
    alacrittyVersion = importJSON ../pkgs/alacritty-git/version.json;
  };

  ananicy-cpp-rules = final.callPackage ../pkgs/ananicy-cpp-rules {
    ananicy-cpp-rules-git-src = flakes.ananicy-cpp-rules-git-src;
  };

  applet-window-appmenu = final.libsForQt5.callPackage ../pkgs/applet-window-appmenu { };

  applet-window-title = final.callPackage ../pkgs/applet-window-title { };

  appmenu-gtk3-module = final.callPackage ../pkgs/appmenu-gtk3-module { };

  beautyline-icons = final.callPackage ../pkgs/beautyline-icons {
    beautyline-icons-git-src = flakes.beautyline-icons-git-src;
  };

  blurredwallpaper = final.callPackage ../pkgs/blurredwallpaper { };

  busybox_appletless = multiOverride
    prev.busybox
    { enableAppletSymlinks = false; }
    (overrideDescription (old: old + " (without applets' symlinks)"));

  bytecode-viewer_git = final.callPackage ../pkgs/bytecode-viewer {
    inherit (flakes) bytecode-viewer-git-src;
  };

  dr460nized-kde-theme = final.callPackage ../pkgs/dr460nized-kde-theme {
    dr460nized-kde-theme-git-src = flakes.dr460nized-kde-theme-git-src;
  };

  droid-sans-mono-nerdfont = multiOverrides
    final.nerdfonts
    { fonts = [ "DroidSansMono" ]; }
    [
      dropUpdateScript
      (overrideDescription (_: "Provides \"DroidSansM Nerd Font\" font family."))
    ];

  fastfetch = final.callPackage ../pkgs/fastfetch { };

  firedragon-unwrapped = final.callPackage ../pkgs/firedragon { };

  firedragon = final.wrapFirefox final.firedragon-unwrapped {
    inherit (final.firedragon-unwrapped) extraPrefsFiles extraPoliciesFiles;
    libName = "firedragon";
  };

  gamescope_git = callOverride ../pkgs/gamescope-git { };

  input-leap_git = callOverride ../pkgs/input-leap-git {
    inherit (final.libsForQt5.qt5) qttools;
  };

  latencyflex-vulkan = final.callPackage ../pkgs/latencyflex-vulkan { };

  linux_cachyos = final.callPackage ../pkgs/linux-cachyos {
    inherit cachyVersions;
    kernelPatches = with final.kernelPatches; [
      bridge_stp_helper
      request_key_helper
    ];
  };

  linuxPackages_cachyos = (dropAttrsUpdateScript
    ((final.linuxPackagesFor final.linux_cachyos).extend cachyZFS)
  ) // { _description = "Kernel modules for linux_cachyos"; };

  luxtorpeda = final.callPackage ../pkgs/luxtorpeda {
    luxtorpedaVersion = importJSON ../pkgs/luxtorpeda/version.json;
  };

  # You should not need "mangohud32_git" since it's embedded in "mangohud_git"
  mangohud_git = callOverride ../pkgs/mangohud-git { mangohud32 = final.mangohud32_git; };
  mangohud32_git =
    if final.stdenv.hostPlatform.isLinux && final.stdenv.hostPlatform.isx86
    then
      callOverride32 ../pkgs/mangohud-git { mangohud32 = final.mangohud32_git; }
    else throw "No mangohud32_git for non-x86";

  mesa_git = callOverride ../pkgs/mesa-git {
    gbmDriver = true;
    meson = final.meson_next;
  };
  mesa32_git =
    if final.stdenv.hostPlatform.isLinux && final.stdenv.hostPlatform.isx86
    then
      callOverride32 ../pkgs/mesa-git { }
    else throw "No mesa32_git for non-x86";

  # Applies be https://github.com/NixOS/nixpkgs/pull/243966
  # since it's a few cycles late.
  meson_next = callOverride ../pkgs/meson-next { };

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

  nordvpn = final.callPackage ../pkgs/nordvpn { };

  openmohaa = final.callPackage ../pkgs/openmohaa {
    openmohaaVersion = importJSON ../pkgs/openmohaa/version.json;
  };

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

  vulkanPackages_latest = callOverride ../pkgs/vulkan-versioned
    { vulkanVersions = importJSON ../pkgs/vulkan-versioned/latest.json; };

  waynergy_git = nyxUtils.gitOverride flakes.waynergy-git-src prev.waynergy;

  wlroots_git = callOverride ../pkgs/wlroots-git { };

  yt-dlp_git = callOverride ../pkgs/yt-dlp-git { };

  yuzu-early-access_git = callOverride ../pkgs/yuzu-ea-git { };

  yyjson = final.callPackage ../pkgs/yyjson { };
}
