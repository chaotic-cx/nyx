{ final
, prev
, vulkanVersions
, ...
}:
let
  genericOverride =
    { origin
    , key ? repo
    , owner
    , repo
    , fetchSubmodules ? false
    , extraInput ? null
    , extraAttrs ? null
    }:
    (if extraInput == null then origin else origin.override extraInput).overrideAttrs (prevAttrs:
      with vulkanVersions.${key}; {
        inherit version;
        src = final.fetchFromGitHub {
          inherit owner repo hash fetchSubmodules;
          rev = builtins.replaceStrings
            [ "#{version}" ] [ version ]
            rev;
        };
        passthru = (prevAttrs.passthru or { }) // {
          updateScript = final.callPackage ./update.nix {
            packageToUpdate = { inherit key owner repo fetchSubmodules; };
          };
        };
      } // (if extraAttrs == null then { } else (extraAttrs prevAttrs)));
in
final.lib.makeScope final.newScope (self:
{
  recurseForDerivations = true;
  vulkanVersions = vulkanVersions // { recurseForDerivations = false; };

  gfxreconstruct = genericOverride {
    origin = prev.gfxreconstruct;
    extraInput = { inherit (self) vulkan-loader; };
    owner = "LunarG";
    repo = "gfxreconstruct";
    fetchSubmodules = true;
  };

  glslang = genericOverride {
    origin = prev.glslang;
    extraInput = { inherit (self) spirv-headers spirv-tools; };
    owner = "KhronosGroup";
    repo = "glslang";
  };

  spirv-cross = genericOverride {
    origin = prev.spirv-cross;
    key = "spirvCross";
    owner = "KhronosGroup";
    repo = "SPIRV-Cross";
  };

  spirv-headers = genericOverride {
    origin = prev.spirv-headers;
    key = "spirvHeaders";
    owner = "KhronosGroup";
    repo = "SPIRV-Headers";
  };

  spirv-tools = genericOverride {
    origin = prev.spirv-tools;
    extraInput = { inherit (self) spirv-headers; };
    key = "spirvTools";
    owner = "KhronosGroup";
    repo = "SPIRV-Tools";
  };

  vulkan-extension-layer = genericOverride {
    origin = prev.vulkan-extension-layer;
    extraInput = { inherit (self) vulkan-headers vulkan-utility-libraries; };
    key = "vulkanExtensionLayer";
    owner = "KhronosGroup";
    repo = "Vulkan-ExtensionLayer";
  };

  vulkan-headers = genericOverride {
    origin = prev.vulkan-headers;
    key = "vulkanHeaders";
    owner = "KhronosGroup";
    repo = "Vulkan-Headers";
  };

  vulkan-loader = genericOverride {
    origin = prev.vulkan-loader;
    extraInput = { inherit (self) vulkan-headers; };
    key = "vulkanLoader";
    owner = "KhronosGroup";
    repo = "Vulkan-Loader";
    extraAttrs = prevAttrs: {
      meta = prevAttrs.meta // { broken = false; };
    };
  };

  vulkan-volk = genericOverride {
    origin = prev.vulkan-volk;
    extraInput = { inherit (self) vulkan-headers; };
    key = "volk";
    owner = "zeux";
    repo = "volk";
  };

  vulkan-tools = genericOverride {
    origin = prev.vulkan-tools;
    extraInput = { inherit (self) vulkan-headers vulkan-loader vulkan-volk; };
    key = "vulkanTools";
    owner = "KhronosGroup";
    repo = "Vulkan-Tools";
  };

  vulkan-tools-lunarg =
    genericOverride {
      origin = prev.vulkan-tools-lunarg;
      extraInput = { inherit (self) vulkan-headers vulkan-loader vulkan-utility-libraries; };
      key = "vulkanToolsLunarG";
      owner = "LunarG";
      repo = "VulkanTools";
      fetchSubmodules = true;
    };

  vulkan-utility-libraries =
    genericOverride {
      origin = prev.vulkan-utility-libraries;
      extraInput = { inherit (self) vulkan-headers; };
      key = "vulkanUtilityLibraries";
      owner = "KhronosGroup";
      repo = "Vulkan-Utility-Libraries";
    };

  vulkan-validation-layers =
    genericOverride {
      origin = prev.vulkan-validation-layers;
      extraInput = {
        inherit (self) glslang vulkan-headers vulkan-utility-libraries spirv-headers;
      };
      key = "vulkanValidationLayers";
      owner = "KhronosGroup";
      repo = "Vulkan-ValidationLayers";
      extraAttrs = prevAttrs: {
        buildInputs = [ self.spirv-tools ] ++ prevAttrs.buildInputs;
      };
    };
})
