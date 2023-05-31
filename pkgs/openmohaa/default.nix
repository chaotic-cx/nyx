{ lib
, clangStdenv
, fetchFromGitHub
, pkg-config
, cmake
, SDL2
, curl
, libogg
, libvorbis
, libopus
}:

clangStdenv.mkDerivation (fa: {
  pname = "openmohaa";
  version = "0.54.0";

  src = fetchFromGitHub {
    owner = "openmoh";
    repo = "openmohaa";
    rev = "v${fa.version}";
    hash = "sha256-2OBbKmjjfo120gr2n5vi3ZxrouHl2knU+NJSRRE6wqU=";
  };

  nativeBuildInputs = [ cmake pkg-config ];
  buildInputs = [
    SDL2
    curl
    libogg
    libvorbis
    libopus
  ];

  cmakeFlags = [
    "-DWITH_CLIENT=1"
    "-DUSE_INTERNAL_LIBS=0"
    "-DUSE_FREETYPE=1"
    "-DUSE_OPENAL_DLOPEN=0"
    "-DUSE_CURL_DLOPEN=0"
  ];

  postPatch = ''
    echo "add_definitions(-w)" >> CMakeLists.txt
  '';

  enableParallelBuilding = true;

  meta = with lib; {
    homepage = "https://github.com/openmoh/openmohaa";
    description = "Open re-implementation of Medal of Honor: Allied Assault ";
    license = licenses.gpl2Only;
    platforms = platforms.linux;
    maintainers = with maintainers; [ peedrohlc ];
  };
})
