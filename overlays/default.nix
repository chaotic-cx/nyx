# - Sort packages in alphabetic order.
# - If the recipe uses `override` or `overrideAttrs`, then use `prev`,
#   otherwise use `final`.
{ inputs }: final: prev:
let
  utils = import ../shared/utils.nix {
    inherit (final) lib;
  };
in
{
  ananicy-cpp-rules-git = final.callPackage ../pkgs/ananicy-cpp-rules-git {
    inherit (inputs) ananicy-rules-git-src;
  };

  applet-window-appmenu = final.libsForQt5.callPackage ../pkgs/applet-window-appmenu { };

  applet-window-title = final.callPackage ../pkgs/applet-window-title { };

  beautyline-icons-git = final.callPackage ../pkgs/beautyline-icons-git {
    inherit (inputs) beautyline-git-src;
  };

  firedragon-unwrapped = final.callPackage ../pkgs/firedragon { };

  firedragon = final.wrapFirefox final.firedragon-unwrapped {
    inherit (final.firedragon-unwrapped) extraPrefsFiles extraPoliciesFiles;
    libName = "firedragon";
  };

  dr460nized-kde-theme-git = final.callPackage ../pkgs/dr460nized-kde-theme-git {
    beautyline-icons-git = final.beautyline-icons-git;
    inherit (inputs) dr460nized-kde-git-src;
  };

  gamescope-git = prev.callPackage ../pkgs/gamescope-git {
    inherit (inputs) gamescope-git-src;
  };

  input-leap-git = prev.callPackage ../pkgs/input-leap-git {
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

  mesa-git = prev.callPackage ../pkgs/mesa-git {
    inherit (inputs) mesa-git-src;
    inherit utils;
  };
  mesa-git-32 =
    if final.stdenv.hostPlatform.isLinux && final.stdenv.hostPlatform.isx86
    then
      prev.pkgsi686Linux.callPackage ../pkgs/mesa-git
        {
          inherit (inputs) mesa-git-src;
          inherit utils;
        }
    else throw "No mesa-git-32 for non-x86";

  sway-unwrapped-git =
    (prev.sway-unwrapped.override {
      wlroots_0_16 = final.wlroots-git;
    }).overrideAttrs (_: {
      version = "1.9-unstable";
      src = inputs.sway-git-src;
    });
  sway-git = prev.sway.override {
    sway-unwrapped = final.sway-unwrapped-git;
  };

  waynergy-git = prev.waynergy.overrideAttrs (_: { src = inputs.waynergy-git-src; });

  wlroots-git = prev.callPackage ../pkgs/wlroots-git {
    inherit (inputs) wlroots-git-src;
  };
}
