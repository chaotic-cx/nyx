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
    extraInput = { inherit (self) vulkan-headers; };
    key = "vulkanExtensionLayer";
    owner = "KhronosGroup";
    repo = "Vulkan-ExtensionLayer";
    extraAttrs = prevAttrs: { buildInputs = prevAttrs.buildInputs ++ [ self.vulkan-utility-libraries ]; };
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
    extraAttrs = prevAttrs: { meta = prevAttrs.meta // { broken = false; }; };
  };

  vulkan-tools = genericOverride {
    origin = prev.vulkan-tools;
    extraInput = { inherit (self) vulkan-headers vulkan-loader; };
    key = "vulkanTools";
    owner = "KhronosGroup";
    repo = "Vulkan-Tools";
  };

  vulkan-tools-lunarg =
    genericOverride {
      origin = prev.vulkan-tools-lunarg;
      extraInput =
        if vulkanVersions.vulkanToolsLunarG.version == "1.3.261.1" then
          { inherit (self) vulkan-validation-layers; }
        else
          { inherit (self) vulkan-headers vulkan-loader vulkan-validation-layers; };
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
      extraInput = { inherit (self) glslang vulkan-headers spirv-headers; };
      key = "vulkanValidationLayers";
      owner = "KhronosGroup";
      repo = "Vulkan-ValidationLayers";
    };
})
