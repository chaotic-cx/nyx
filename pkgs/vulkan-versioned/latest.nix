# When upgrading vulkanPackages_sdk, remember to upgrade MoltenVK as well.
rec {
  gfxreconstructVersion = "1.0.0";
  gfxreconstructRev = "v${gfxreconstructVersion}";
  gfxreconstructHash = "sha256-EVwO0ov0zZ+sPq4RBunLCzuGaYPA2y1hKpFC/mcoFGM=";

  glslangVersion = "1.3.250.1";
  glslangRev = "sdk-${spirvCrossVersion}";
  glslangHash = "sha256-JGB7sKyTCy3ujumro730dgeqOqzkOptbxajXlgrDKEM=";

  # Same version as SDK
  spirvCrossVersion = "1.3.250.1";
  spirvCrossRev = "sdk-${spirvCrossVersion}";
  spirvCrossHash = "sha256-H4UkR/EiBWpdhdPHNBrdRkl4eN8kD9gEOzpnwfFSdpI=";

  spirvHeadersVersion = "1.3.250.1";
  spirvHeadersRev = "sdk-${spirvHeadersVersion}";
  spirvHeadersHash = "sha256-5mVcbOAuzux/Yuo0NMwZRTsdQr46UxjrtMhT5mPHyCQ=";

  spirvToolsVersion = "1.3.250.1";
  spirvToolsRev = "sdk-${spirvToolsVersion}";
  spirvToolsHash = "sha256-HV7jNvgTRRGnhurtT5pf5f5gzUOmr3iWNcDc8TE4ICQ=";

  vulkanHeadersVersion = "1.3.257";
  vulkanHeadersRev = "v${vulkanHeadersVersion}";
  vulkanHeadersHash = "sha256-TBluDNKMvQiB7KQGnyv7YIRF8qPbKocc8Lqbcza6IRI=";

  vulkanLoaderVersion = "1.3.256";
  vulkanLoaderRev = "v${vulkanLoaderVersion}";
  vulkanLoaderHash = "sha256-sMmdeHSh7wXT4jRQuO5RNiaT4wItpQBcxXBD0qNSQQY=";

  vulkanToolsVersion = "1.3.255";
  vulkanToolsRev = "v${vulkanToolsVersion}";
  vulkanToolsHash = "sha256-z972ohH0ol8J5PbdlQqXDrs2ogCnN0pZH7k7wFUMlGw=";

  vulkanToolsLunarGVersion = "1.3.250.1";
  vulkanToolsLunarGRev = "sdk-${vulkanToolsLunarGVersion}";
  vulkanToolsLunarGHash = "sha256-eNTGrf4DbFA9mJ5jHbP+2Im+wU1zfjz7RCrcEPqC0sg=";

  vulkanExtensionLayerVersion = "1.3.255";
  vulkanExtensionLayerRev = "v${vulkanExtensionLayerVersion}";
  vulkanExtensionLayerHash = "sha256-k0bRfFNNdC0yFzZo2+n+fu5zZ8Zcra6Do+M/KYBUYj4=";

  vulkanValidationLayersVersion = "1.3.256";
  vulkanValidationLayersRev = "v${vulkanValidationLayersVersion}";
  vulkanValidationLayersHash = "sha256-sEtfbl8ELSE0862Sc/kbteYYz8mY55dxAHZy0q8hcww=";
}
