{ final
, nyxUtils
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
    (if extraInput == null then origin else origin.override extraInput).overrideAttrs (pa:
      with vulkanVersions.${key}; {
        inherit version;
        src = final.fetchFromGitHub {
          inherit owner repo hash fetchSubmodules;
          rev = builtins.replaceStrings
            [ "#{version}" ] [ version ]
            rev;
        };
        passthru = (pa.passthru or { }) // {
          updateScript = final.callPackage ./update.nix {
            packageToUpdate = { inherit key owner repo fetchSubmodules; };
          };
        };
      } // (if extraAttrs == null then { } else (extraAttrs pa)));
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
    extraAttrs = pa: {
      patches = [ ];
      postInstall = pa.postInstall + ''
        pushd $out/bin
        ln -s glslang glslangValidator
        popd
      '';
    };
  };

  spirv-cross = genericOverride {
    origin = prev.spirv-cross;
    key = "spirvCross";
    owner = "KhronosGroup";
    repo = "SPIRV-Cross";
    extraAttrs = pa: {
      postPatch = ''
        substituteInPlace pkg-config/spirv-cross-c.pc.in \
          --replace '=''${prefix}/@' '=@'
      '' + (pa.postPatch or "");
    };
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
    extraAttrs = pa: {
      nativeBuildInputs = pa.nativeBuildInputs ++ [ final.pkg-config ];
      buildInputs = pa.buildInputs ++ (with final; [ xorg.libxcb xorg.libX11 xorg.libXrandr wayland ]);
    };
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
    extraAttrs = pa: { meta = pa.meta // { broken = false; }; };
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
      extraInput = { inherit (self) vulkan-headers vulkan-loader vulkan-validation-layers; };
      key = "vulkanToolsLunarG";
      owner = "LunarG";
      repo = "VulkanTools";
      fetchSubmodules = true;
      extraAttrs = pa: {
        nativeBuildInputs = pa.nativeBuildInputs ++ [ final.xorg.libXau ];
        buildInputs = pa.buildInputs ++ [ final.jsoncpp ];
        patches = nyxUtils.removeByBaseName "skip-qnx-extension.patch" pa.patches;
        postPatch = ''
          substituteInPlace via/CMakeLists.txt \
            --replace 'jsoncpp_static' 'jsoncpp'
        '' + (pa.postPatch or "");
      };
    };

  vulkan-utility-libraries =
    genericOverride {
      origin = final.callPackage ./utility-libraries.nix { };
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
      extraAttrs = pa: {
        nativeBuildInputs = pa.nativeBuildInputs ++ [ self.vulkan-utility-libraries ];
        cmakeFlags = nyxUtils.replaceStartingWith
          "-DSPIRV_HEADERS_INSTALL_DIR=" "${self.spirv-headers}"
          pa.cmakeFlags;
      };
    };
})
