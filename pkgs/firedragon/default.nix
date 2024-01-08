{ buildMozillaMach
, callPackage
, lib
, stdenv
}:
let
  firedragon-src = callPackage ./firedragon.nix { };
in
(buildMozillaMach rec {
  pname = "firedragon";
  applicationName = "FireDragon";
  binaryName = "firedragon";
  version = firedragon-src.packageVersion;
  src = firedragon-src.firefox;
  inherit (firedragon-src) extraConfigureFlags extraPatches extraPostPatch extraPassthru;

  updateScript = callPackage ./update.nix { };

  meta = {
    badPlatforms = lib.platforms.darwin;
    broken = stdenv.buildPlatform.is32bit; # since Firefox 60, build on 32-bit platforms fails with "out of memory".
    description = "A fork of LibreWolf, focused on being easier to use";
    homepage = "https://github.com/dr460nf1r3/firedragon-browser";
    license = lib.licenses.mpl20;
    maintainers = with lib; [ maintainers.dr460nf1r3 ];
    maxSilent = 14400; # 4h, double the default of 7200s (c.f. #129212, #129115)
    platforms = lib.platforms.unix;
    mainProgram = "firedragon";
  };
}).override {
  crashreporterSupport = false;
  enableOfficialBranding = false;
  pgoSupport = false; # Profiling gets stuck and doesn't terminate.
}
