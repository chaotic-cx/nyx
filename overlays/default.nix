# - Sort packages in alphabetic order.
# - If the recipe uses `override` or `overrideAttrs`, then use `prev`,
#   otherwise use `final`.
# - Composed names are separated with minus: input-leap
# - Versions/varitions are suffixed with an underline: mesa_git, libei_0_5, linux_hdr

{ inputs }: final: prev:
let
  utils = import ../shared/utils.nix {
    inherit (final) lib;
  };
in
{
  ananicy-cpp-rules = final.callPackage ../pkgs/ananicy-cpp-rules { };

  applet-window-appmenu = final.libsForQt5.callPackage ../pkgs/applet-window-appmenu { };

  applet-window-title = final.callPackage ../pkgs/applet-window-title { };

  beautyline-icons = final.callPackage ../pkgs/beautyline-icons { };

  firedragon-unwrapped = final.callPackage ../pkgs/firedragon { };

  firedragon = final.wrapFirefox final.firedragon-unwrapped {
    inherit (final.firedragon-unwrapped) extraPrefsFiles extraPoliciesFiles;
    libName = "firedragon";
  };

  dr460nized-kde-theme = final.callPackage ../pkgs/dr460nized-kde-theme { };

  gamescope_git = prev.callPackage ../pkgs/gamescope-git {
    inherit (inputs) gamescope-git-src;
  };

  input-leap_git = prev.callPackage ../pkgs/input-leap-git {
    inherit (inputs) input-leap-git-src;
    libei = final.libei_0_4;
    qttools = final.libsForQt5.qt5.qttools;
  };

  libei_0_4 = final.callPackage ../pkgs/libei {
    libeiVersion = "0.4.1";
    libeiSrcHash = "sha256-wjzzOU/wvs4QeRCQMH56TARONx+LjYFVMHgWWM/XOs4=";
  };
  libei_0_5 = final.callPackage ../pkgs/libei { };
  libei = final.libei_0_5;

  linux_hdr = final.callPackage ../pkgs/linux-hdr {
    kernelPatches = with final.kernelPatches; [
      bridge_stp_helper
      request_key_helper
    ];
  };

  linuxPackages_hdr = final.linuxPackagesFor final.linux_hdr;

  mesa_git = prev.callPackage ../pkgs/mesa-git {
    inherit (inputs) mesa-git-src;
    inherit utils;
  };
  mesa32_git =
    if final.stdenv.hostPlatform.isLinux && final.stdenv.hostPlatform.isx86
    then
      prev.pkgsi686Linux.callPackage ../pkgs/mesa-git
        {
          inherit (inputs) mesa-git-src;
          inherit utils;
        }
    else throw "No mesa32_git for non-x86";

  sway-unwrapped_git =
    (prev.sway-unwrapped.override {
      wlroots_0_16 = final.wlroots_git;
      wayland = final.wayland_next;
    }).overrideAttrs (_: {
      version = "1.9-unstable";
      src = inputs.sway-git-src;
    });
  sway_git = prev.sway.override {
    sway-unwrapped = final.sway-unwrapped_git;
  };

  wayland_next = prev.wayland.overrideAttrs (_: rec {
    version = "1.22.0";
    src = final.fetchurl {
      url = "https://gitlab.freedesktop.org/wayland/wayland/-/releases/${version}/downloads/wayland-${version}.tar.xz";
      hash = "sha256-FUCvHqaYpHHC2OnSiDMsfg/TYMjx0Sk267fny8JCWEI=";
    };
  });

  waynergy_git = prev.waynergy.overrideAttrs (_: { src = inputs.waynergy-git-src; });

  wlroots_git = prev.callPackage ../pkgs/wlroots-git {
    inherit (inputs) wlroots-git-src;
    inherit (final) wayland_next;
  };
}
