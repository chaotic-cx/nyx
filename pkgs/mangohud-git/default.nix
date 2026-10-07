{
  final,
  prev,
  gitOverride,
  ...
}:

gitOverride (
  current:
  let
    inherit (final.stdenv.hostPlatform) is32bit;

    subprojects = final.lib.mapAttrsToList (name: data: {
      inherit name;
      inherit (data) directory;

      src = final.fetchurl {
        url = data.src.url;
        sha256 = data.src.hash;
      };

      patch =
        if data ? patch then
          final.fetchurl {
            url = data.patch.url;
            sha256 = data.patch.hash;
          }
        else
          null;
    }) current.subprojects;

    imguiDir = current.subprojects.imgui.directory;

    extractSubproject =
      { directory, src, ... }:
      if final.lib.strings.hasSuffix ".zip" src then
        ''
          unzip -q ${src} -d ${directory}
        ''
      else
        ''
          mkdir -p ${directory}
          tar -xzf ${src} -C ${directory} --strip-components=1
        '';

    extractSubprojectPatch =
      { patch, name, ... }:
      if patch == null then
        "# No patch for ${name}"
      else
        ''
          unzip -o ${patch}
        '';

    extractSubprojectRename = { directory, name, ... }: ''
      mv ${directory} ${name}
    '';

    # yaml-cpp 0.9.0 truncates dragonbox's 64-bit significand to `size_t` on 32-bit platforms.
    yaml-cpp =
      if is32bit then
        final.yaml-cpp.overrideAttrs (old: {
          postPatch = (old.postPatch or "") + ''
            substituteInPlace src/fptostring.cpp \
              --replace-fail 'size_t value' 'uint64_t value'
          '';
        })
      else
        final.yaml-cpp;
  in
  {
    nyxKey = if is32bit then "mangohud32_git" else "mangohud_git";
    prev = prev.mangohud;

    manifestPath = "pkgs/mangohud-git/manifest.json";
    fetcher = "fetchFromGitHub";
    fetcherData = {
      owner = "flightlessmango";
      repo = "MangoHud";
    };
    ref = "master";
    withUpdateScript = !is32bit;

    withExtraUpdateCommands = final.writeShellScript "bump-grammars" ''
      PATH="$PATH:${final.jq}/bin"
      ${builtins.readFile ./extra-update.sh}
    '';

    postOverride = prevAttrs: {
      doCheck = !is32bit;

      nativeBuildInputs = (prevAttrs.nativeBuildInputs or [ ]) ++ [
        final.wayland-scanner
      ];

      buildInputs = (prevAttrs.buildInputs or [ ]) ++ [
        final.vulkan-loader
        final.vk-bootstrap
        final.libdrm
        final.libgbm
        final.systemdLibs
        final.libcap
        final.libxcb
        yaml-cpp
        final.wayland-protocols
        final.wlr-protocols
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

          ${builtins.concatStringsSep "\n" (builtins.map extractSubproject subprojects)}

          cp -R ${final.vk-bootstrap.src} vk-bootstrap
          chmod -R +w vk-bootstrap
        )
      '';

      # Completely override postPatch to avoid version mismatches and conflicts
      postPatch = ''
        # Fix spdlog and fmt includes for system spdlog/fmt
        substituteInPlace mangohud-next/server/metrics/metrics.cpp \
          --replace '<spdlog/fmt/bundled/format.h>' '<fmt/format.h>
        #include <fmt/ranges.h>'

        substituteInPlace mangohud-next/client/wayland.cpp \
          --replace '#include "wayland.h"' '#include "wayland.h"
        #include <fmt/ranges.h>'

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
          ${builtins.concatStringsSep "\n" (builtins.map extractSubprojectPatch subprojects)}

          # Rename to the canonical names meson expects
          ${builtins.concatStringsSep "\n" (builtins.map extractSubprojectRename subprojects)}

          # No good idea to deal with this
          mv implot/implot-*/* implot/

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

          if [ -d "packagefiles/${imguiDir}" ]; then
            cp -R "packagefiles/${imguiDir}"/* imgui/
          fi
        )
      '';
    };
  }
)
