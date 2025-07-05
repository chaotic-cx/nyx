{
  fetchurl,
  lib,
  pkgs,
  ...
}:
let
  current = lib.trivial.importJSON ./version.json;
  packageVersion = current.firedragonSource.version;
in
rec {
  extraConfigureFlags = [
    "--allow-addon-sideload"

    "--disable-debug-js-modules"
    "--disable-default-browser-agent"
    "--disable-elf-hack"
    "--disable-necko-wifi"
    "--disable-parental-controls"
    "--disable-rust-tests"
    "--disable-synth-speechd"
    "--disable-warnings-as-errors"
    "--disable-webspeech"
    "--disable-webspeechtestbackend"
    "--enable-av1"
    "--enable-bundled-fonts"
    "--enable-eme=widevine"
    "--enable-hardening"
    ''--enable-optimize="-O3"''
    "--enable-jxl"
    "--enable-proxy-bypass-protection"
    "--enable-raw"
    "--enable-rust-simd"
    "--enable-sandbox"
    "--enable-unverified-updates"
    "--enable-update-channel=release"
    "--enable-wasm-simd"

    "--with-app-basename=FireDragon"
    "--with-distribution-id=org.garudalinux"
    "--with-firedragon-settings=firedragon/settings"
    "--with-noraneko-buildid2=firedragon/_dist/buildid2"
    "--with-noraneko-dist=firedragon/_dist/noraneko"
    "--with-unsigned-addon-scopes=app,system"
  ];

  extraMakeFlags = [
    "MOZ_SERVICES_HEALTHREPORT=0"
  ];

  extraNativeBuildInputs = [ pkgs.zstd ];

  extraPassthru = {
    firedragon = { inherit src; };
  };

  inherit packageVersion;

  src = fetchurl {
    url = "https://gitlab.com/garuda-linux/firedragon/firedragon12/-/releases/v${packageVersion}/downloads/firedragon-source.tar.zst";
    inherit (current.firedragonSource) hash;
  };

  version = current.firefoxVersion;
}
