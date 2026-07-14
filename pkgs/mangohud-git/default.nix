{
  final,
  prev,
  gitOverride,
  ...
}:

let
  inherit (final.stdenv) is32bit;

  # Subproject definitions from MangoHud master (rev 7f4201f86b6754dbeb8863e404b14e7356186d1c)
  imgui = rec {
    version = "1.91.6";
    src = final.fetchurl {
      url = "https://github.com/ocornut/imgui/archive/refs/tags/v${version}.tar.gz";
      hash = "sha256-xfvF3KsdRgZAAcO4TXqIgSmFzefg6c7QP1Z3vsG6UCo=";
    };
    patch = final.fetchurl {
      url = "https://wrapdb.mesonbuild.com/v2/imgui_${version}-3/get_patch";
      hash = "sha256-L3l3EUugfQZVmq+IkKkqTr0lGGWS1ER5VGBaryJEY00=";
    };
  };

  implot = rec {
    version = "0.16";
    src = final.fetchurl {
      url = "https://github.com/epezent/implot/archive/refs/tags/v${version}.zip";
      hash = "sha256-JPdyxoj2uKbhnX78EOSSOgSpFfE9SHsIuDVTqmKuFwg=";
    };
    patch = final.fetchurl {
      url = "https://wrapdb.mesonbuild.com/v2/implot_${version}-1/get_patch";
      hash = "sha256-HGsUYgZqVFL6UMHaHdR/7YQfKCMpcsgtd48pYpNlaMc=";
    };
  };

  vulkan-headers = rec {
    version = "1.4.346";
    src = final.fetchurl {
      url = "https://github.com/KhronosGroup/Vulkan-Headers/archive/v${version}.tar.gz";
      hash = "sha256-W7d/XXtGDiVanlGv/ADWQ1SYa1XPV32OqyhSnK0B/IA=";
    };
  };

  vulkan-utility-libraries = rec {
    version = "1.4.346";
    src = final.fetchurl {
      url = "https://github.com/KhronosGroup/Vulkan-Utility-Libraries/archive/v${version}.tar.gz";
      hash = "sha256-Ny61JRA+y046BNAwsql3jrxnhTu9yCzmdH3jdX1DKtk=";
    };
  };

  vkroots = rec {
    version = "5106d8a0df95de66cc58dc1ea37e69c99afc9540";
    src = final.fetchurl {
      url = "https://github.com/Joshua-Ashton/vkroots/archive/${version}.tar.gz";
      hash = "sha256-N7d1hukffr7nA4Dc3dc78BrkrO8QU+a+QdBIXt4CJCI=";
    };
  };
in
gitOverride {
  nyxKey = if is32bit then "mangohud32_git" else "mangohud_git";
  prev = prev.mangohud;

  versionNyxPath = "pkgs/mangohud-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "flightlessmango";
    repo = "MangoHud";
  };
  ref = "master";
  withUpdateScript = !final.stdenv.is32bit;

  postOverride = prevAttrs: {
    nativeBuildInputs = (prevAttrs.nativeBuildInputs or [ ]) ++ [
      final.unzip
      final.wayland-scanner
    ];

    buildInputs = (prevAttrs.buildInputs or [ ]) ++ [
      final.vulkan-loader
      final.vk-bootstrap
      final.libdrm
      final.libgbm
      final.systemd
      final.libcap
      final.yaml-cpp
      final.wayland-protocols
    ];

    patches = builtins.filter (
      patch:
      let
        name = patch.name or (baseNameOf (toString patch));
      in
      builtins.match ".*preload-nix-workaround.*" name == null
    ) (prevAttrs.patches or [ ]);

    # Overlay nixpkgs' postUnpack to use our updated versions
    postUnpack = ''
      (
        cd "$sourceRoot/subprojects"

        # Extract imgui
        mkdir imgui-src
        tar -xzf ${imgui.src} -C imgui-src --strip-components=1
        cp -R imgui-src imgui-${imgui.version}
        rm -rf imgui-src

        # Extract implot
        mkdir implot-src
        unzip -q ${implot.src} -d implot-src
        cp -R implot-src/* implot-${implot.version}
        rm -rf implot-src

        # Extract vulkan-headers
        mkdir vulkan-src
        tar -xzf ${vulkan-headers.src} -C vulkan-src --strip-components=1
        cp -R vulkan-src Vulkan-Headers-${vulkan-headers.version}
        rm -rf vulkan-src

        # Extract vulkan-utility-libraries
        mkdir vulkan-utility-libraries-src
        tar -xzf ${vulkan-utility-libraries.src} -C vulkan-utility-libraries-src --strip-components=1
        cp -R vulkan-utility-libraries-src Vulkan-Utility-Libraries-${vulkan-utility-libraries.version}
        rm -rf vulkan-utility-libraries-src

        mkdir vkroots-src
        tar -xzf ${vkroots.src} -C vkroots-src --strip-components=1
        cp -R vkroots-src vkroots-${vkroots.version}
        rm -rf vkroots-src

        cp -R ${final.vk-bootstrap.src} vk-bootstrap
        chmod -R +w vk-bootstrap
      )
    '';

    # Completely override postPatch to avoid version mismatches and conflicts
    postPatch = ''
      # preload-nix-workaround.patch
      substituteInPlace bin/mangohud.in \
        --replace '@ld_libdir_mangohud@@mangohud_lib_name@' '@mangohud_lib_name@'

      substituteInPlace bin/mangohud.in \
        --replace 'disable_preload=false' 'disable_preload=false
          XDG_DATA_DIRS="@dataDir@''${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}"'

      substituteInPlace bin/mangohud.in \
        --replace 'exec env @mangohud_env@=1 "$@"' 'exec env @mangohud_env@=1 XDG_DATA_DIRS="''${XDG_DATA_DIRS}" "$@"'

      substituteInPlace bin/mangohud.in \
        --replace 'exec env @mangohud_env@=1 LD_PRELOAD="''${LD_PRELOAD}" "$@"' \
                  'LD_LIBRARY_PATH="@libraryPath@''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"; exec env @mangohud_env@=1 LD_PRELOAD="''${LD_PRELOAD}" LD_LIBRARY_PATH="''${LD_LIBRARY_PATH}" XDG_DATA_DIRS="''${XDG_DATA_DIRS}" "$@"'

      # Re-apply the substituteInPlace logic from nixpkgs but with correct version context
      substituteInPlace bin/mangohud.in \
        --subst-var-by libraryPath ${
          final.lib.makeSearchPath "lib/mangohud" (
            [
              (placeholder "out")
            ]
            ++ final.lib.optional final.stdenv.hostPlatform.isx86_64 final.pkgsi686Linux.mangohud
          )
        } \
        --subst-var-by version "${prevAttrs.version}" \
        --subst-var-by dataDir ${placeholder "out"}/share

      (
        cd subprojects
        # Delete redundant wrap files and clear old directories to avoid conflicts
        rm -f *.wrap

        # Apply patches (unzip into directories that nixpkgs expects, then we rename them)
        unzip -o ${imgui.patch}
        unzip -o ${implot.patch}

        # Rename to the canonical names meson expects
        mv imgui-${imgui.version} imgui
        mv implot-${implot.version} implot
        mv Vulkan-Headers-${vulkan-headers.version} vulkan-headers
        mv Vulkan-Utility-Libraries-${vulkan-utility-libraries.version} vulkan-utility-libraries
        mv vkroots-${vkroots.version} vkroots

        # Use bundled meson.build for vulkan-headers if available
        if [ -d packagefiles/vulkan-headers ]; then
          cp packagefiles/vulkan-headers/meson.build vulkan-headers/
        fi

        # Use bundled meson.build for vulkan-utility-libraries if available
        if [ -d packagefiles/vulkan-utility-libraries ]; then
          cp packagefiles/vulkan-utility-libraries/meson.build vulkan-utility-libraries/
        fi

        if [ -d packagefiles/vk-bootstrap ]; then
          cp -R packagefiles/vk-bootstrap/* vk-bootstrap/
        fi
      )
    '';
  };
}
