{ lib
, stdenv
, fetchFromGitHub
, cmake
, vulkan-headers
}:

# Right now it's building a static library, which should be
# enough for our usage...

stdenv.mkDerivation rec {
  pname = "vulkan-utility-libraries";
  version = "1.3.261";

  src = fetchFromGitHub {
    owner = "KhronosGroup";
    repo = "Vulkan-Utility-Libraries";
    rev = "v${version}";
    hash = "sha256-cE/h/muoK94gWuhyLJ7Ong12dMnLYWzYoeTGMa9FOGM=";
  };

  nativeBuildInputs = [ cmake vulkan-headers ];

  meta = with lib; {
    description = "Settings for vulkan layers";
    homepage = "https://www.lunarg.com";
    platforms = platforms.unix;
    license = licenses.asl20;
    maintainers = [ maintainers.pedrohlc ];
  };
}
