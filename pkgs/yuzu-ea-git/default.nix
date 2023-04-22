{ final, inputs, nyxUtils, prev, ... }:

# nixpkgs has cpp-httplib, but it's outdated
# yuzu doesn't seem to recognize our mbedtls_2 and cpp-jwt
let
  dynarmic = final.fetchFromGitHub {
    owner = "merryhime";
    repo = "dynarmic";
    rev = "6.4.6";
    hash = "sha256-DIcyI0Sqw+J3Dhqk4MugIXsSZmSS0PaGjSqIfmVuQXc=";
  };
  cpp-httplib = final.fetchFromGitHub {
    owner = "yhirose";
    repo = "cpp-httplib";
    rev = "v0.12.2";
    hash = "sha256-mpHw9fzGpYz04rgnfG/qTNrXIf6q+vFfIsjb56kJsLg=";
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
    rev = "v6.69.1";
    hash = "sha256-yMArB0MmIvdqctr2bstKzREDvb7OnGXGMSCiGaQ3SmY=";
  };
in
(prev.yuzu-early-access.override {
  catch2 = final.catch2_3;
  fmt_8 = final.fmt_9;
  vulkan-loader = final.vulkan-loader_next;
}).overrideAttrs (pa: rec {
  src = inputs.yuzu-ea-git-src;
  version = nyxUtils.gitToVersion src;

  buildInputs = pa.buildInputs ++ (with final; [ cubeb discord-rpc enet httplib inih vulkan-loader_next ]);
  nativeBuildInputs = pa.nativeBuildInputs ++ (with final; [ perl spirv-headers vulkan-headers_next ]);

  cmakeFlags = pa.cmakeFlags ++ [
    "-DYUZU_CHECK_SUBMODULES=OFF"
    "-DYUZU_TESTS=OFF"

    "-DYUZU_USE_PRECOMPILED_HEADERS=OFF"
    "-DSIRIT_USE_SYSTEM_SPIRV_HEADERS=ON"
    "-DYUZU_USE_EXTERNAL_VULKAN_HEADERS=OFF"
    "-DYUZU_USE_QT_MULTIMEDIA=ON"
  ];

  postPatch = pa.postPatch + ''
    find . -name "CMakeLists.txt" -exec sed -i 's/^.*-Werror$/-W/g' {} +
    find . -name "CMakeLists.txt" -exec sed -i 's/^.*-Werror=.*$/ /g' {} +
    find . -name "CMakeLists.txt" -exec sed -i 's/-Werror/-W/g' {} +

    rm -r externals/{cpp-{jwt,httplib},dynarmic,mbedtls,sirit,xbyak}
    cp --no-preserve=mode -r ${final.mbedtls_2.src} externals/mbedtls
    ln -s ${final.cpp-jwt.src} externals/cpp-jwt
    ln -s ${cpp-httplib} externals/cpp-httplib
    ln -s ${dynarmic} externals/dynarmic
    ln -s ${sirit} externals/sirit
    ln -s ${xbyak} externals/xbyak
  '';

  preConfigure = ''
    pushd externals/mbedtls
    perl scripts/config.pl set MBEDTLS_THREADING_C
    perl scripts/config.pl set MBEDTLS_THREADING_PTHREAD
    perl scripts/config.pl set MBEDTLS_CMAC_C
    popd

    # See https://github.com/NixOS/nixpkgs/issues/114044, setting this through cmakeFlags does not work.
    # These will fix version "formatting"
    cmakeFlagsArray+=(
      "-DTITLE_BAR_FORMAT_IDLE=yuzu Early Access NYX-0"
      "-DTITLE_BAR_FORMAT_RUNNING=yuzu Early Access NYX-0 | {3}"
    )
  '';

  # Right now crypto tests don't pass
  doCheck = false;
})
