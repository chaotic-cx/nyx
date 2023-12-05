{ lib
, stdenv
, fetchFromGitHub
, cmake
, pkg-config
, python3
, vulkan-headers
, vulkan-loader
}:

stdenv.mkDerivation rec {
  pname = "volk";
  version = "1.3.270";

  src = fetchFromGitHub {
    owner = "zeux";
    repo = "volk";
    rev = "${version}";
    hash = "sha256-qf3MygaUSN31AnlR/5o0W7cqA85Fc9aT+XemaLNfWzI=";
  };

  nativeBuildInputs = [
    cmake
    pkg-config
    python3
  ];

  buildInputs = [
    vulkan-headers
    vulkan-loader
  ];

  cmakeFlags = [
    "-DVOLK_INSTALL=ON"
  ];

  meta = with lib; {
    description = "Meta loader for Vulkan API";
    longDescription = "Dynamically load entrypoints required to use Vulkan";
    homepage = "https://github.com/zeux/volk";
    license = licenses.mit;
  };
}
