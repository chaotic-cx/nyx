{ stdenv
, lib
, fetchFromGitHub
, runCommand
, cmake
, meson
, ninja
, pkg-config
, vulkanPackages_latest
}:

let
  inherit (vulkanPackages_latest) vulkan-headers vulkan-loader vulkan-validation-layers;
  vulkan-validation-layers-headers =
    runCommand "vulkan-validation-layers-headers" { } ''
      mkdir -p $out/vulkan
      cd $out/vulkan
      cp ${vulkan-validation-layers.src}/layers/vulkan/generated/* ./
      cp -r ${vulkan-validation-layers.src}/layers/vulkan/{*/,vk_layer_config.*} ./
    '';
in
stdenv.mkDerivation {
  pname = "latencyflex-vulkan";
  version = "unstable-2023-07-03";

  src = fetchFromGitHub {
    owner = "ishitatsuyuki";
    repo = "LatencyFleX";
    rev = "3bc9636f94a3220ce55edb642077349e396a7d6a";
    hash = "sha256-Ic7jTdXVKFZQ+L5F+qSRmvNnXIMMQX70mawAjuvIwm8=";
    fetchSubmodules = true;
  };

  sourceRoot = "source/layer";

  nativeBuildInputs = [
    meson
    cmake
    ninja
    pkg-config
    vulkan-headers
  ];

  buildInputs = [ vulkan-loader vulkan-validation-layers ];

  preConfigure = ''
    export CFLAGS="$CFLAGS -I${vulkan-validation-layers-headers}"
    export CPPFLAGS="$CPPFLAGS -I${vulkan-validation-layers-headers}"
  '';

  meta = with lib; {
    description = "Vulkan Layer for LatencyFleX";
    homepage = "https://github.com/ishitatsuyuki/LatencyFleX";
    license = licenses.asl20;
    platforms = platforms.linux;
    maintainers = with maintainers; [ pedrohlc ];
  };
}
