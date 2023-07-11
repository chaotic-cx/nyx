{ final
, prev
, vulkanVersions ? import ./latest.nix
, ...
}:
(final.lib.makeScope final.newScope (self:
{
  vulkanVersions = self.dontRecurseIntoAttrs vulkanVersions;

  #gfxreconstruct = (prev.gfxreconstruct.override
  #  { inherit (self) vulkan-loader; }).overrideAttrs (pa: with vulkanVersions; {
  #  nativeBuildInputs = pa.nativeBuildInputs ++ [ self.vulkan-headers ];
  #  version = gfxreconstructVersion;
  #  src = final.fetchFromGitHub {
  #    owner = "LunarG";
  #    repo = "gfxreconstruct";
  #    rev = gfxreconstructRev;
  #    hash = gfxreconstructHash;
  #  };
  #  meta = pa.meta // { broken = gfxreconstructVersion == "1.0.0"; };
  #});

  glslang = (prev.glslang.override
    { inherit (self) spirv-headers spirv-tools; }).overrideAttrs (pa: with vulkanVersions; {
    version = glslangVersion;
    patches = [ ];
    src = final.fetchFromGitHub {
      owner = "KhronosGroup";
      repo = "glslang";
      rev = glslangRev;
      hash = glslangHash;
    };
  });

  spirv-cross = prev.spirv-cross.overrideAttrs (pa: with vulkanVersions; {
    version = spirvCrossVersion;
    src = final.fetchFromGitHub {
      owner = "KhronosGroup";
      repo = "SPIRV-Cross";
      rev = spirvCrossRev;
      hash = spirvCrossHash;
    };
  });
  spirv-headers = prev.spirv-headers.overrideAttrs (pa: with vulkanVersions; {
    version = spirvHeadersVersion;
    src = final.fetchFromGitHub {
      owner = "KhronosGroup";
      repo = "SPIRV-Headers";
      rev = spirvHeadersRev;
      hash = spirvHeadersHash;
    };
  });
  spirv-tools = (prev.spirv-tools.override
    { inherit (self) spirv-headers; }).overrideAttrs (pa: with vulkanVersions; {
    version = spirvToolsVersion;
    src = final.fetchFromGitHub {
      owner = "KhronosGroup";
      repo = "SPIRV-Tools";
      rev = spirvToolsRev;
      hash = spirvToolsHash;
    };
  });

  vulkan-extension-layer = (prev.vulkan-extension-layer.override
    { inherit (self) vulkan-headers; }).overrideAttrs (pa: with vulkanVersions; {
    nativeBuildInputs = pa.nativeBuildInputs ++ [ final.pkg-config ];
    version = vulkanExtensionLayerVersion;
    src = final.fetchFromGitHub {
      owner = "KhronosGroup";
      repo = "Vulkan-ExtensionLayer";
      rev = vulkanExtensionLayerRev;
      hash = vulkanExtensionLayerHash;
    };
  });

  vulkan-headers = prev.vulkan-headers.overrideAttrs (pa: with vulkanVersions; {
    version = vulkanHeadersVersion;
    src = final.fetchFromGitHub {
      owner = "KhronosGroup";
      repo = "Vulkan-Headers";
      rev = vulkanHeadersRev;
      hash = vulkanHeadersHash;
    };
  });
  vulkan-loader = (prev.vulkan-loader.override
    { inherit (self) vulkan-headers; }).overrideAttrs (pa: with vulkanVersions; {
    version = vulkanLoaderVersion;
    src = final.fetchFromGitHub {
      owner = "KhronosGroup";
      repo = "Vulkan-Loader";
      rev = vulkanLoaderRev;
      hash = vulkanLoaderHash;
    };
    meta = pa.meta // { broken = false; };
  });
  vulkan-tools = (prev.vulkan-tools.override
    { inherit (self) vulkan-headers vulkan-loader; }).overrideAttrs (pa: with vulkanVersions; {
    version = vulkanToolsVersion;
    src = final.fetchFromGitHub {
      owner = "KhronosGroup";
      repo = "Vulkan-Tools";
      rev = vulkanToolsRev;
      hash = vulkanToolsHash;
    };
  });
  #vulkan-tools-lunarg = (prev.vulkan-tools-lunarg.override
  #  { inherit (self) vulkan-headers vulkan-loader vulkan-validation-layers; }).overrideAttrs (pa: with vulkanVersions; {
  #  nativeBuildInputs = pa.nativeBuildInputs ++ [ final.xorg.libXau ];
  #  version = vulkanToolsLunarGVersion;
  #  src = final.fetchFromGitHub {
  #    owner = "LunarG";
  #    repo = "VulkanTools";
  #    rev = vulkanToolsLunarGRev;
  #    hash = vulkanToolsLunarGHash;
  #    fetchSubmodules = true;
  #  };
  #});
  #vulkan-validation-layers = (prev.vulkan-validation-layers.override
  #  { inherit (self) vulkan-headers spirv-headers; }).overrideAttrs (pa: with vulkanVersions; {
  #  version = vulkanValidationLayersVersion;
  #  src = final.fetchFromGitHub {
  #    owner = "KhronosGroup";
  #    repo = "Vulkan-ValidationLayers";
  #    rev = vulkanValidationLayersRev;
  #    hash = vulkanValidationLayersHash;
  #  };
  #  meta = pa.meta // { broken = vulkanValidationLayersVersion == "1.3.256" && vulkanHeadersVersion == "1.3.257"; };
  #});
}))
