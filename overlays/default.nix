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
  gamescope-git = prev.callPackage ../pkgs/gamescope-git {
    inherit (inputs) gamescope-git-src;
  };

  input-leap-git = prev.callPackage ../pkgs/input-leap-git {
    inherit (inputs) input-leap-git-src;
    inherit (final) libei;
    qttools = final.libsForQt5.qt5.qttools;
  };

  libei = final.callPackage ../pkgs/libei { };

  linux_hdr = final.callPackage ../pkgs/linux-hdr {
    kernelPatches = with final.kernelPatches; [
      bridge_stp_helper
      request_key_helper
    ];
  };

  linuxPackages_hdr = final.linuxPackagesFor final.linux_hdr;

  mesa-git = prev.callPackage ../pkgs/mesa-git { inherit (inputs) mesa-git-src; inherit utils; };
  mesa-git-32 =
    if final.stdenv.hostPlatform.isLinux && final.stdenv.hostPlatform.isx86 then
      prev.pkgsi686Linux.callPackage ../pkgs/mesa-git { inherit (inputs) mesa-git-src; inherit utils; }
    else throw "No mesa-git-32 for non-x86";

  sway-unwrapped-git = (prev.sway-unwrapped.override {
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
