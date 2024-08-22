{ buildMozillaMach
, callPackage
, lib
, nyxUtils
, stdenv
}:
let
  firedragon-src = callPackage ./firedragon.nix { };

  mach = ((buildMozillaMach {
    applicationName = "FireDragon";
    binaryName = "firedragon";
    pname = "firedragon";
    branding = "browser/branding/firedragon";
    requireSigning = false;
    allowAddonSideload = true;

    inherit (firedragon-src) extraConfigureFlags extraNativeBuildInputs extraPassthru packageVersion src version;

    updateScript = callPackage ./update.nix { };

    meta = {
      badPlatforms = lib.platforms.darwin;
      description = "Floorp fork build using custom branding & settings";
      homepage = "https://firedragon.garudalinux.org";
      license = lib.licenses.mpl20;
      maintainers = with lib; [ maintainers.dr460nf1r3 ];
      broken = stdenv.buildPlatform.is32bit;
      maxSilent = 14400;
      platforms = lib.platforms.unix;
      mainProgram = "firedragon";
    };
  }).override {
    crashreporterSupport = false;
    enableOfficialBranding = false;
    pgoSupport = true;
    privacySupport = true;
    webrtcSupport = true;
  }).overrideAttrs {
    MOZ_APP_REMOTINGNAME = "firedragon";
    MOZ_CRASHREPORTER = "";
    MOZ_DATA_REPORTING = "";
    MOZ_TELEMETRY_REPORTING = "";
    OPT_LEVEL = "3";
    RUSTC_OPT_LEVEL = "3";
  };

  postOverride = prevAttrs: {
    patches = nyxUtils.removeByName "cbindgen-0.27.0-compat.patch" prevAttrs.patches;
  };
in

nyxUtils.multiOverride mach { } postOverride
