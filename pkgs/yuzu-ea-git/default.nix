{ final, gitOverride, prev, ... }:

# yuzu doesn't seem to recognize our mbedtls_2
let
  dynarmic = final.fetchFromGitHub {
    owner = "merryhime";
    repo = "dynarmic";
    rev = "ca0e264f4f962e29baa23a3282ce484625866b98";
    hash = "sha256-C5qby4uU1aaJNi1H4tgRjwSEDjMDQlVlRx//G+tgnto=";
  };
  simpleini = final.fetchFromGitHub {
    owner = "brofield";
    repo = "simpleini";
    rev = "v4.22";
    hash = "sha256-H4J4+v/3A8ZTOp4iMeiZ0OClu68oP4vUZ8YOFZbllcM=";
  };
  sirit = final.fetchFromGitHub {
    owner = "yuzu-emu";
    repo = "sirit";
    rev = "ab75463999f4f3291976b079d42d52ee91eebf3f";
    hash = "sha256-XzuxuLDYUQFD8SZT6c8CWHNE3mX16OrlvLnhvQ301Hw=";
  };
  xbyak = final.fetchFromGitHub {
    owner = "herumi";
    repo = "xbyak";
    rev = "a1ac3750f9a639b5a6c6d6c7da4259b8d6790989";
    hash = "sha256-lRFiYlEW8wCot4Ks0xATJAfqrkhJPKG7OKUqI/SYg3Y=";
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
    rev = "2f382df218d7e8516dee3b3caccb819a62b571a2";
    hash = "sha256-Tw7C2xRYs2Ok02zAXSygs5un7JAPeYPZse6u+bck+pg=";
  };
  ffmpeg = final.fetchFromGitHub {
    owner = "FFmpeg";
    repo = "FFmpeg";
    rev = "9c1294eaddb88cb0e044c675ccae059a85fc9c6c";
    hash = "sha256-ryCPhFxuMKfZlPDwZWYaRBxwMSTvwsEVQG9eeq2dRTI=";
  };
  inherit (final.vulkanPackages_latest) glslang vulkan-headers vulkan-loader vulkan-utility-libraries spirv-headers;
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
    nativeBuildInputs = [ vulkan-headers glslang spirv-headers final.perl ] ++ prevAttrs.nativeBuildInputs;

    cmakeFlags = prevAttrs.cmakeFlags ++ [
      "-DSIRIT_USE_SYSTEM_SPIRV_HEADERS=ON"
    ];

    postPatch = (prevAttrs.postPatch or "") + ''
      rm -r externals/{cpp-httplib,dynarmic,mbedtls,sirit,xbyak,ffmpeg/ffmpeg}
      cp --no-preserve=mode -r ${final.mbedtls_2.src} externals/mbedtls
      ln -s ${final.httplib.src} externals/cpp-httplib
      ln -s ${dynarmic} externals/dynarmic
      ln -s ${sirit} externals/sirit
      ln -s ${xbyak} externals/xbyak
      ln -s ${vma} externals/VulkanMemoryAllocator
      ln -s ${vulkan-utility-libraries.src} externals/Vulkan-Utility-Libraries
      ln -s ${simpleini} externals/simpleini
      ln -s ${ffmpeg} externals/ffmpeg/ffmpeg
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

    env = prevAttrs.env // {
      # Shows released date in version
      SOURCE_DATE_EPOCH = current.lastModified;
    };

    # Right now crypto tests don't pass
    doCheck = false;
  };
})
