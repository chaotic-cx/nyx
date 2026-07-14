{
  final,
  prev,
  vulkanVersions,
  nyxUtils,
  ...
}:
let
  inherit (final.lib.attrsets) optionalAttrs;

  genericOverride =
    {
      origin,
      key ? origin.pname,
      id ? repo,
      owner,
      repo,
      fetchSubmodules ? false,
      withUpdateScript ? true,
      extraInput ? null,
      extraAttrs ? null,
      knownGoods ? null,
    }:
    (if extraInput == null then origin else origin.override extraInput).overrideAttrs (
      prevAttrs:
      with vulkanVersions.${id};
      {
        inherit version;
        src = final.fetchFromGitHub {
          inherit
            owner
            repo
            hash
            fetchSubmodules
            ;
          rev = builtins.replaceStrings [ "#{version}" ] [ version ] rev;
        };
        passthru =
          (prevAttrs.passthru or { })
          // optionalAttrs withUpdateScript {
            updateScript = final.callPackage ./update.nix {
              packageToUpdate = {
                inherit
                  key
                  id
                  owner
                  repo
                  fetchSubmodules
                  knownGoods
                  ;
              };
            };
          };
      }
      // (if extraAttrs == null then { } else (extraAttrs prevAttrs))
    );
in
final.lib.makeScope final.newScope (self: {
  recurseForDerivations = true;
  vulkanVersions = vulkanVersions // {
    recurseForDerivations = false;
  };

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

    # updated by validation-layer
    withUpdateScript = false;

    # Removed the obsolete external-gtest.patch which is now upstream.
    extraAttrs = prevAttrs: {
      patches = builtins.filter (p: !final.lib.hasSuffix "external-gtest.patch" (toString p)) (
        prevAttrs.patches or [ ]
      );
      # Vulkan stacks frequently fail transient SPIR-V tests
      doCheck = false;
    };
  };

  spirv-cross = genericOverride {
    origin = prev.spirv-cross;
    owner = "KhronosGroup";
    repo = "SPIRV-Cross";
  };

  spirv-headers = genericOverride {
    origin = prev.spirv-headers;
    owner = "KhronosGroup";
    repo = "SPIRV-Headers";

    # updated by validation-layer
    withUpdateScript = false;

    extraAttrs = prevAttrs: {
      patches = builtins.filter (
        patch:
        !(
          final.lib.hasInfix "1a22b167081842915a1c78a0b5b5a353a23284aa" (toString patch)
          || final.lib.hasInfix "b8a32968473ce852a809b9de5f04f02a5a9dfa78" (toString patch)
        )
      ) (prevAttrs.patches or [ ]);
    };
  };

  spirv-tools = genericOverride {
    origin = prev.spirv-tools;
    extraInput = { inherit (self) spirv-headers; };
    owner = "KhronosGroup";
    repo = "SPIRV-Tools";

    # updated by validation-layer
    withUpdateScript = false;

    extraAttrs = prevAttrs: {
      patches = builtins.filter (
        patch: !final.lib.hasInfix "2ec8457ab33d539b6f1fecc998360c0b8b05ed4f" (toString patch)
      ) (prevAttrs.patches or [ ]);
    };
  };

  vulkan-extension-layer = genericOverride {
    origin = prev.vulkan-extension-layer;
    extraInput = { inherit (self) vulkan-headers vulkan-utility-libraries; };
    owner = "KhronosGroup";
    repo = "Vulkan-ExtensionLayer";
  };

  vulkan-headers = genericOverride {
    origin = prev.vulkan-headers;
    owner = "KhronosGroup";
    repo = "Vulkan-Headers";
  };

  vulkan-loader = genericOverride {
    origin = prev.vulkan-loader;
    extraInput = { inherit (self) vulkan-headers; };
    owner = "KhronosGroup";
    repo = "Vulkan-Loader";
    extraAttrs = prevAttrs: {
      meta = prevAttrs.meta // {
        broken = false;
      };
    };
  };

  vulkan-volk = genericOverride {
    origin = prev.vulkan-volk;
    extraInput = { inherit (self) vulkan-headers; };
    owner = "zeux";
    repo = "volk";
  };

  vulkan-tools = genericOverride {
    origin = prev.vulkan-tools;
    extraInput = { inherit (self) vulkan-headers vulkan-loader vulkan-volk; };
    owner = "KhronosGroup";
    repo = "Vulkan-Tools";
    extraAttrs = prevAttrs: {
      cmakeFlags = nyxUtils.replaceStartingWith "-DBUILD_CUBE=" "ON" prevAttrs.cmakeFlags;
    };
  };

  vulkan-tools-lunarg = genericOverride {
    id = "LunarG-Tools";
    origin = prev.vulkan-tools-lunarg;
    extraInput = { inherit (self) vulkan-headers vulkan-loader vulkan-utility-libraries; };
    owner = "LunarG";
    repo = "VulkanTools";
    fetchSubmodules = true;
    extraAttrs = _prevAttrs: {
      preConfigure = ''
        patchShebangs scripts/*
      '';
    };
  };

  vulkan-utility-libraries = genericOverride {
    origin = prev.vulkan-utility-libraries;
    extraInput = { inherit (self) vulkan-headers; };
    owner = "KhronosGroup";
    repo = "Vulkan-Utility-Libraries";
  };

  vulkan-validation-layers = genericOverride {
    origin = prev.vulkan-validation-layers;
    extraInput = {
      inherit (self)
        glslang
        vulkan-headers
        vulkan-utility-libraries
        spirv-headers
        spirv-tools
        ;
    };
    owner = "KhronosGroup";
    repo = "Vulkan-ValidationLayers";

    knownGoods = [
      "SPIRV-Headers"
      "SPIRV-Tools"
      "glslang"
    ];

    extraAttrs = prevAttrs: {
      nativeBuildInputs = prevAttrs.nativeBuildInputs or [ ] ++ [
        final.python3
      ];

      buildInputs =
        (prevAttrs.buildInputs or [ ])
        ++ final.lib.optionals final.stdenv.hostPlatform.isLinux [
          final.libxext
        ];

      cmakeFlags = (prevAttrs.cmakeFlags or [ ]) ++ [
        # Disable the internal update_deps.py script.
        "-DUPDATE_DEPS=OFF"
      ];
    };
  };
})
