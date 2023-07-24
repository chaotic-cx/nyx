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
  inherit (final.lib.trivial) importJSON;

  nyxUtils = final.callPackage ../shared/utils.nix { } //
    { _description = "Pack of functions that are useful for Chaotic-Nyx and might become useful for you too"; };

  callOverride = path: attrs: import path ({ inherit final flakes nyxUtils prev; } // attrs);

  callOverride32 = path: attrs: import path ({
    inherit flakes nyxUtils;
    final = final.pkgsi686Linux;
    prev = prev.pkgsi686Linux;
  } // attrs);

  cachyVersions = importJSON ../pkgs/linux-cachyos/versions.json;

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

  dropUpdateScript = pa: { passthru = pa.passthru // { updateScript = null; }; };

  dropAttrsUpdateScript = builtins.mapAttrs (_: v:
    if (v.passthru.updateScript or null) != null then
      v.overrideAttrs dropUpdateScript
    else v
  );
in
{
  inherit nyxUtils;

  ananicy-cpp-rules = final.callPackage ../pkgs/ananicy-cpp-rules { };

  applet-window-appmenu = final.libsForQt5.callPackage ../pkgs/applet-window-appmenu { };

  applet-window-title = final.callPackage ../pkgs/applet-window-title { };

  appmenu-gtk3-module = final.callPackage ../pkgs/appmenu-gtk3-module { };

  beautyline-icons = final.callPackage ../pkgs/beautyline-icons { };

  blurredwallpaper = final.callPackage ../pkgs/blurredwallpaper { };

  busybox_appletless = prev.busybox.override {
    enableAppletSymlinks = false;
  };

  dr460nized-kde-theme = final.callPackage ../pkgs/dr460nized-kde-theme { };

  # nixpkgs builds this one, but does not expose it.
  droid-sans-mono-nerdfont = (final.nerdfonts.override {
    fonts = [ "DroidSansMono" ];
  }).overrideAttrs dropUpdateScript;

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

  luxtorpeda = final.callPackage ../pkgs/luxtorpeda { };

  # You should not need "mangohud32_git" since it's embedded in "mangohud_git"
  mangohud_git = callOverride ../pkgs/mangohud-git { mangohud32 = final.mangohud32_git; };
  mangohud32_git =
    if final.stdenv.hostPlatform.isLinux && final.stdenv.hostPlatform.isx86
    then
      callOverride32 ../pkgs/mangohud-git { mangohud32 = final.mangohud32_git; }
    else throw "No mangohud32_git for non-x86";

  mesa_git = callOverride ../pkgs/mesa-git { gbmDriver = true; };
  mesa32_git =
    if final.stdenv.hostPlatform.isLinux && final.stdenv.hostPlatform.isx86
    then
      callOverride32 ../pkgs/mesa-git { }
    else throw "No mesa32_git for non-x86";

  mpv-vapoursynth =
    final.wrapMpv (final.mpv-unwrapped.override { vapoursynthSupport = true; }) {
      extraMakeWrapperArgs = [
        "--prefix"
        "LD_LIBRARY_PATH"
        ":"
        "${final.vapoursynth-mvtools}/lib/vapoursynth"
      ];
    };

  nordvpn = final.callPackage ../pkgs/nordvpn { };

  openmohaa = final.callPackage ../pkgs/openmohaa { };

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

  vulkanPackages_latest =
    callOverride ../pkgs/vulkan-versioned
      { vulkanVersions = importJSON ../pkgs/vulkan-versioned/latest.json; }
    //
    { _description = "Latest versions of vulkan-*, spirv-*, glslang, and gfxreconstruct (in a scope)"; };

  waynergy_git = nyxUtils.gitOverride flakes.waynergy-git-src prev.waynergy;

  wlroots_git = callOverride ../pkgs/wlroots-git { };

  yt-dlp_git = callOverride ../pkgs/yt-dlp-git { };

  yuzu-early-access_git = callOverride ../pkgs/yuzu-ea-git { };
}
