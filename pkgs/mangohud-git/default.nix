{ final, prev, gitOverride, nyxUtils, ... }:

let
  # Derived from subprojects/imgui.wrap
  imgui = rec {
    version = "1.89.9";
    src = final.fetchFromGitHub {
      owner = "ocornut";
      repo = "imgui";
      rev = "refs/tags/v${version}";
      hash = "sha256-0k9jKrJUrG9piHNFQaBBY3zgNIKM23ZA879NY+MNYTU=";
    };
    patch = final.fetchurl {
      url = "https://wrapdb.mesonbuild.com/v2/imgui_${version}-1/get_patch";
      hash = "sha256-myEpDFl9dr+NTus/n/oCSxHZ6mxh6R1kjMyQtChD1YQ=";
    };
  };

  # Derived from subprojects/implot.wrap
  implot = rec {
    version = "0.16";
    src = final.fetchFromGitHub {
      owner = "epezent";
      repo = "implot";
      rev = "refs/tags/v${version}";
      hash = "sha256-/wkVsgz3wiUVZBCgRl2iDD6GWb+AoHN+u0aeqHHgem0=";
    };
    patch = final.fetchurl {
      url = "https://wrapdb.mesonbuild.com/v2/implot_${version}-1/get_patch";
      hash = "sha256-HGsUYgZqVFL6UMHaHdR/7YQfKCMpcsgtd48pYpNlaMc=";
    };
  };
in
gitOverride {
  newInputs = with final; { mangohud32 = mangohud32_git; };
  nyxKey = if final.stdenv.is32bit then "mangohud32_git" else "mangohud_git";
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
    buildInputs = prevAttrs.buildInputs ++ [ final.SDL2 ];
    patches = [ ./preload-nix-workaround.patch ] ++
      (nyxUtils.removeByBaseName "preload-nix-workaround.patch"
        (nyxUtils.removeByURL "https://github.com/flightlessmango/MangoHud/commit/3f8f036ee8773ae1af23dd0848b6ab487b5ac7de.patch"
          prevAttrs.patches
        ));
    postUnpack = prevAttrs.postUnpack + ''#
        (
          cd "$sourceRoot/subprojects"
          echo "IMGUI"
          cp -R --no-preserve=mode,ownership ${imgui.src} imgui-${imgui.version}
          echo "IMPLOT"
          cp -R --no-preserve=mode,ownership ${implot.src} implot-${implot.version}
        )
      '';
    postPatch = prevAttrs.postPatch + ''
      (
        cd subprojects
        unzip ${imgui.patch}
        unzip ${implot.patch}
      )
      substituteInPlace src/meson.build \
        --replace 'glfw3_dep,' 'glfw3_dep, dep_vulkan,' \
        --replace "run_command(['git', 'describe', '--tags', '--dirty=+']).stdout().strip()" \
          "'${prevAttrs.version}'"
      substituteInPlace meson.build \
        --replace 'cmocka_dep,' 'cmocka_dep, dep_vulkan,'
    '';
  };
}
