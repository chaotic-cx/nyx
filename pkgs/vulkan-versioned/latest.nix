# When upgrading vulkanPackages_sdk, remember to upgrade MoltenVK as well.
rec {
  gfxreconstructVersion = "1.0.0";
  gfxreconstructRev = "v${gfxreconstructVersion}";
  gfxreconstructHash = "sha256-dOmkNKURYgphbDHOmzcWf9PsIKMkPyN7ve579BE7fR0=";

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

  vulkanLoaderVersion = "1.3.257";
  vulkanLoaderRev = "v${vulkanLoaderVersion}";
  vulkanLoaderHash = "sha256-RSCym/a2O8t+FvckqSg41U6ET9eXFQuRh8d4F144D2c=";

  vulkanToolsVersion = "1.3.257";
  vulkanToolsRev = "v${vulkanToolsVersion}";
  vulkanToolsHash = "sha256-eUihRn6czFiDYyyXcXKDqmPDq+0czVdVqmclpg/Lzhg=";

  vulkanToolsLunarGVersion = "1.3.257";
  vulkanToolsLunarGRev = "v${vulkanToolsLunarGVersion}";
  vulkanToolsLunarGHash = "sha256-I3H47DCxVlbHjl+2plmqIJdgnpXfnGESJgrsZ8CcmD0=";

  vulkanExtensionLayerVersion = "1.3.257";
  vulkanExtensionLayerRev = "v${vulkanExtensionLayerVersion}";
  vulkanExtensionLayerHash = "sha256-VEaQNkCBqawgz88Yu+aos6LskEbh99bSmuo6g9UnNPg=";

  vulkanValidationLayersVersion = "1.3.257";
  vulkanValidationLayersRev = "v${vulkanValidationLayersVersion}";
  vulkanValidationLayersHash = "sha256-YsFhSgL/2YPq0Cbs9rFWzUf17UCfwrqLnhx7AmNNR1M=";
}
