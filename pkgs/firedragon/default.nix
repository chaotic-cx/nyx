{ buildMozillaMach
, callPackage
, lib
}:
let
  firedragon-src = callPackage ./firedragon.nix { };
in
((buildMozillaMach {
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
    homepage = "https://github.com/dr460nf1r3/firedragon-browser";
    license = lib.licenses.mpl20;
    maintainers = with lib; [ maintainers.dr460nf1r3 ];
    # broken = stdenv.buildPlatform.is32bit; # since Firefox 60, build on 32-bit platforms fails with "out of memory".
    maxSilent = 14400; # 4h, double the default of 7200s (c.f. #129212, #129115)
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
}
