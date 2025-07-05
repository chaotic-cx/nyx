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
  # If I cannot change MOZ_OBJDIR when building through buildMozillaMach,
  # I'll have firedragon adapt
  extraPostPatch = ''
    for f in firedragon/{build,make}.ts; do
      substituteInPlace "$f" \
        --replace-fail obj-artifact-build-output objdir
    done
  '';

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
    # FIXME: it's hardcoded upstream
    # "MOZ_OBJDIR=@TOPSRCDIR@/obj-artifact-build-output"
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
