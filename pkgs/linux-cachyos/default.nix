{ pkgs
, stdenv
, lib
, fetchFromGitHub
, buildLinux
, lto ? false
, ...
} @ args:
# https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/os-specific/linux/kernel/linux-xanmod.nix
# Taken & updated from https://github.com/VolodiaPG/nur-packages
let
  _major = "6";
  _minor = "2";
  _rc = "9";

  major = "${_major}.${_minor}";
  minor = _rc;
  version = "${major}.${minor}";
  release = "1";

  patches-src = fetchFromGitHub {
    owner = "CachyOS";
    repo = "kernel-patches";
    rev = "8d374579e993cc89ea6c8fc8781f94235707dfeb";
    sha256 = "IpwEe8Wh6FIhnC8fqtBn/KjM0mU59p8Q0NMf1wZkMLk=";
  };

  config-src = fetchFromGitHub {
    owner = "CachyOS";
    repo = "linux-cachyos";
    rev = "8237304919f2fe7845d969e649113cc6227baee2";
    sha256 = "M2zWHI5TyD0a+oQjW3fz9bjInp87BHtfPd3BIHapvd0=";
  };

  # https://github.com/NixOS/nixpkgs/pull/129806
  stdenvLLVM =
    let
      llvmPin = pkgs.llvmPackages_latest.override {
        bootBintools = null;
        bootBintoolsNoLibc = null;
      };

      stdenv' = pkgs.overrideCC llvmPin.stdenv llvmPin.clangUseLLVM;
    in
    stdenv'.override {
      extraNativeBuildInputs = [ llvmPin.lld pkgs.patchelf ];
    };

  configfile = builtins.storePath (
    builtins.toFile "config" (lib.concatStringsSep "\n"
      (map (builtins.getAttr "configLine") "${config-src}/linux-cachyos/config"))
  );
in
buildLinux {
  inherit lib version;

  allowImportFromDerivation = true;
  defconfig = "${config-src}/linux-cachyos/config";

  stdenv =
    if lto
    then stdenvLLVM
    else stdenv;
  extraMakeFlags = lib.optionals lto [ "LLVM=1" "LLVM_IAS=1" ];

  src = fetchTarball {
    url = "https://cdn.kernel.org/pub/linux/kernel/v${_major}.x/linux-${version}.tar.xz";
    sha256 = "09xbz17h5ni2zrjbcf53pssfablzxjzsk7ljagl9dlqxkp6sly5v";
  };

  modDirVersion = "${version}-cachyos-bore";

  structuredExtraConfig =
    let
      cfg = import ./config.nix args;
    in
    if lto
    then
      ((builtins.removeAttrs cfg [ "GCC_PLUGINS" "FORTIFY_SOURCE" ])
        // (with lib.kernel; {
        LTO_NONE = no;
        LTO_CLANG_FULL = yes;
      }))
    else cfg;

  config = {
    # needed to get the vm test working. whatever.
    isEnabled = f: true;
    isYes = f: true;
  };

  kernelPatches =
    builtins.map
      (name: {
        inherit name;
        patch = name;
      })
      [
        "${patches-src}/${major}/all/0001-cachyos-base-all.patch"
        "${patches-src}/${major}/misc/0001-Add-latency-priority-for-CFS-class.patch"
        "${patches-src}/${major}/sched/0001-bore-cachy.patch"
      ];

  extraMeta.broken = !stdenv.hostPlatform.isx86_64;
}
