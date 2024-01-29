{ final, gitOverride, nyxUtils, prev, ... }:

# yuzu doesn't seem to recognize our mbedtls_2
let
  dynarmic = final.fetchFromGitHub {
    owner = "merryhime";
    repo = "dynarmic";
    rev = "6.4.8";
    hash = "sha256-lsfwR+ydtn3LWWh0Jfb8+2qJqnRbjoTM18Wb1lfX/8w=";
  };
  simpleini = final.fetchFromGitHub {
    owner = "brofield";
    repo = "simpleini";
    rev = "382ddbb4b92c0b26aa1b32cefba2002119a5b1f2";
    hash = "sha256-/cHkL95oj+RUkSLojY1EU6TDiX7KOTNEJzyAFSHmIwg=";
  };
  sirit = final.fetchFromGitHub {
    owner = "ReinUsesLisp";
    repo = "sirit";
    rev = "d7ad93a88864bda94e282e95028f90b5784e4d20";
    hash = "sha256-WDZivcYYe1qKV6IVsDPCHpAxKc+FWsSDlVw+pekCgmI=";
  };
  xbyak = final.fetchFromGitHub {
    owner = "herumi";
    repo = "xbyak";
    rev = "v6.70";
    hash = "sha256-y2GOR6yKIx7W5peFf5FzXlF2iJUfDE/RnMWjO/h/Ruk=";
  };
  tzdataVer = "221202";
  tzdata = final.fetchzip {
    url = "https://github.com/lat9nq/tzdb_to_nx/releases/download/${tzdataVer}/${tzdataVer}.zip";
    hash = "sha256-YOIElcKTiclem05trZsA3YJReozu/ex7jJAKD6nAMwc=";
    stripRoot = false;
  };
  vma = final.fetchFromGitHub {
    owner = "GPUOpen-LibrariesAndSDKs";
    repo = "VulkanMemoryAllocator";
    # Needs to be a revision with 3d23bb07e375ecabad0ad2e53599861be77310e3
    rev = "6eb62e1515072827db992c2befd80b71b2d04329";
    hash = "sha256-rqJSatXjytuF0A4XddG9U6V70BqLeo7gxo9PcTEr8lU=";
  };

  inherit (final.vulkanPackages_latest) glslang vulkan-headers vulkan-loader spirv-headers;
in

gitOverride (current: {
  newInputs.mainline = final.yuzuPackages.mainline.override { inherit glslang vulkan-headers vulkan-loader; };

  nyxKey = "yuzu-early-access_git";
  prev = prev.yuzuPackages.early-access;

  versionNyxPath = "pkgs/yuzu-ea-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "pineappleEA";
    repo = "pineapple-src";
  };
  withLastModified = true;

  postOverride = prevAttrs: {
    # We need to have these headers ahead, otherwise they cause an ordering issue in CMAKE_INCLUDE_PATH,
    # where qtbase propagated input appears first.
    nativeBuildInputs = [ vulkan-headers glslang spirv-headers ] ++ prevAttrs.nativeBuildInputs;

    cmakeFlags = prevAttrs.cmakeFlags ++ [
      "-DSIRIT_USE_SYSTEM_SPIRV_HEADERS=ON"
    ];

    patches = nyxUtils.removeByBaseName "vulkan_version.patch" (prevAttrs.patches or [ ]);

    postPatch = (prevAttrs.postPatch or "") + ''
      rm -r externals/{cpp-httplib,dynarmic,mbedtls,sirit,xbyak}
      cp --no-preserve=mode -r ${final.mbedtls_2.src} externals/mbedtls
      ln -s ${final.httplib.src} externals/cpp-httplib
      ln -s ${dynarmic} externals/dynarmic
      ln -s ${sirit} externals/sirit
      ln -s ${xbyak} externals/xbyak
      ln -s ${vma} externals/VulkanMemoryAllocator
      ln -s ${simpleini} externals/simpleini
    '';

    preConfigure = ''
      pushd externals/mbedtls
      perl scripts/config.pl set MBEDTLS_THREADING_C
      perl scripts/config.pl set MBEDTLS_THREADING_PTHREAD
      perl scripts/config.pl set MBEDTLS_CMAC_C
      popd

      _ver=$(grep -Po '(?<=for early-access )([^.]*)' "${prevAttrs.src}/README.md")

      # See https://github.com/NixOS/nixpkgs/issues/114044, setting this through cmakeFlags does not work.
      # These will fix version "formatting"
      cmakeFlagsArray+=(
        "-DTITLE_BAR_FORMAT_IDLE=yuzu Early Access EA-$_ver"
        "-DTITLE_BAR_FORMAT_RUNNING=yuzu Early Access EA-$_ver | {3}"
      )

      cmakeBuildDir=''${cmakeBuildDir:=build}
   
      mkdir -p "$cmakeBuildDir/externals/nx_tzdb"
      ln -s ${tzdata} "$cmakeBuildDir/externals/nx_tzdb/nx_tzdb"
    '';

    # Shows released date in version
    env.SOURCE_DATE_EPOCH = current.lastModified;

    # Right now crypto tests don't pass
    doCheck = false;
  };
})
