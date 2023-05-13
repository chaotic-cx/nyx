# Conventions:
# - Sort packages in alphabetic order.
# - If the recipe uses `override` or `overrideAttrs`, then use callOverride,
#   otherwise use `final`.
# - Composed names are separated with minus: `input-leap`
# - Versions/patches are suffixed with an underline: `mesa_git`, `libei_0_5`, `linux_hdr`
# - Use `inherit (final) nyxUtils` since someone might want to override our utils

# NOTE:
# - `*_next` packages will be removed once merged into nixpkgs-unstable.

{ inputs }: final: prev:
let
  nyxUtils = final.callPackage ../shared/utils.nix { };

  callOverride = path: attrs: import path ({ inherit final inputs nyxUtils prev; } // attrs);

  callOverride32 = path: attrs: import path ({
    inherit inputs nyxUtils;
    final = final.pkgsi686Linux;
    prev = prev.pkgsi686Linux;
  } // attrs);
in
{
  inherit nyxUtils;

  ananicy-cpp-rules = final.callPackage ../pkgs/ananicy-cpp-rules { };

  applet-window-appmenu = final.libsForQt5.callPackage ../pkgs/applet-window-appmenu { };

  applet-window-title = final.callPackage ../pkgs/applet-window-title { };

  appmenu-gtk3-module = final.callPackage ../pkgs/appmenu-gtk3-module { };

  beautyline-icons = final.callPackage ../pkgs/beautyline-icons { };

  # Upstream is up-to-date (2023-05-01)
  directx-headers_next = final.directx-headers;

  # Upstream is up-to-date (2023-05-01)
  directx-headers32_next =
    if final.stdenv.hostPlatform.isLinux && final.stdenv.hostPlatform.isx86
    then
      final.pkgsi686Linux.directx-headers
    else throw "No headers32_next for non-x86";

  dr460nized-kde-theme = final.callPackage ../pkgs/dr460nized-kde-theme { };

  # nixpkgs builds this one, but does not expose it.
  droid-sans-mono-nerdfont = final.nerdfonts.override {
    fonts = [ "DroidSansMono" ];
  };

  fastfetch = final.callPackage ../pkgs/fastfetch { };

  firedragon-unwrapped = final.callPackage ../pkgs/firedragon { };

  firedragon = final.wrapFirefox final.firedragon-unwrapped {
    inherit (final.firedragon-unwrapped) extraPrefsFiles extraPoliciesFiles;
    libName = "firedragon";
  };

  gamescope_git = callOverride ../pkgs/gamescope-git { };

  input-leap_git = callOverride ../pkgs/input-leap-git {
    libei = final.libei_0_4;
    inherit (final.libsForQt5.qt5) qttools;
  };

  latencyflex-vulkan = final.callPackage ../pkgs/latencyflex-vulkan { };

  libei = final.libei_0_5;
  libei_0_4 = final.callPackage ../pkgs/libei {
    libeiVersion = "0.4.1";
    libeiSrcHash = "sha256-wjzzOU/wvs4QeRCQMH56TARONx+LjYFVMHgWWM/XOs4=";
  };
  libei_0_5 = final.callPackage ../pkgs/libei { };

  linux_cachyos = final.callPackage ../pkgs/linux-cachyos {
    kernelPatches = with final.kernelPatches; [
      bridge_stp_helper
      request_key_helper
    ];
  };

  linux_hdr = final.callPackage ../pkgs/linux-hdr {
    kernelPatches = with final.kernelPatches; [
      bridge_stp_helper
      request_key_helper
    ];
  };

  linuxPackages_cachyos = final.linuxPackagesFor final.linux_cachyos;

  linuxPackages_hdr = final.linuxPackagesFor final.linux_hdr;

  luxtorpeda = final.callPackage ../pkgs/luxtorpeda { };

  mangohud_git = callOverride ../pkgs/mangohud-git { };

  mesa_git = callOverride ../pkgs/mesa-git {
    directx-headers = final.directx-headers_next;
  };
  mesa32_git =
    if final.stdenv.hostPlatform.isLinux && final.stdenv.hostPlatform.isx86
    then
      callOverride32 ../pkgs/mesa-git
        {
          directx-headers = final.directx-headers32_next;
        }
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

  proton-ge-custom = final.callPackage ../pkgs/proton-ge-custom {
    protonGeTitle = "Proton-GE";
  };

  sway-unwrapped_git = callOverride ../pkgs/sway-unwrapped-git {
    wayland = final.wayland_next;
  };
  sway_git = prev.sway.override {
    sway-unwrapped = final.sway-unwrapped_git;
  };

  swaylock-plugin_git = callOverride ../pkgs/swaylock-plugin-git { };

  # Upstream is up-to-date (2023-05-01)
  vulkan-headers_next = final.vulkan-headers;

  # Upstream is up-to-date (2023-05-01)
  vulkan-loader_next = final.vulkan-loader;

  # Upstream is up-to-date (2023-05-01)
  wayland_next = final.wayland;

  waynergy_git = nyxUtils.gitOverride inputs.waynergy-git-src prev.waynergy;

  wlroots_git = callOverride ../pkgs/wlroots-git {
    wayland = final.wayland_next;
  };

  yuzu-early-access_git = callOverride ../pkgs/yuzu-ea-git { };

  zfs_cachyos = final.linuxPackages_cachyos.zfsUnstable.overrideAttrs (pa: {
    src =
      final.fetchFromGitHub {
        owner = "cachyos";
        repo = "zfs";
        rev = "ac18dc77f3703940682aecb442f4e58aa2c14f1a";
        hash = "sha256-wrMZYENs4hmrHXcSN4kYgntaDDs5IwOMeWWqUKortbw=";
      };
    meta = pa.meta // { broken = false; };
    patches = [];
  });
}
