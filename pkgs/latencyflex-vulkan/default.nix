{ stdenv
, lib
, fetchFromGitHub
, runCommand
, cmake
, meson
, ninja
, pkg-config
, vulkan-headers
, vulkan-loader
, vulkan-validation-layers
}:

let
  vulkan-validation-layers-headers =
    runCommand "vulkan-validation-layers-headers" { } ''
      mkdir -p $out/vulkan
      cd $out/vulkan
      cp ${vulkan-validation-layers.headers}/include/vulkan/generated/* ./
      cp -r ${vulkan-validation-layers.headers}/include/vulkan/{*/,vk_layer_config.*} ./
    '';
in
stdenv.mkDerivation {
  pname = "latencyflex-vulkan";
  version = "unstable-2023-04-16";

  src = fetchFromGitHub {
    owner = "ishitatsuyuki";
    repo = "LatencyFleX";
    rev = "73bcb07a20db14ba2d6fbb7a6076e4c2a6cbcc8d";
    hash = "sha256-/rVfpKZFh+1wEJcQzF4E03Cn+bhQKVTM7QblZRDWFZ8=";
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
