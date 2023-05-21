{ lib
, clangStdenv
, fetchFromGitHub
, pkg-config
, cmake
, SDL2
, openalSoft
, curl
, libogg
, libvorbis
, libopus
, freeglut
, libGL
, libXext
, libXxf86dga
, libXxf86vm
}:

clangStdenv.mkDerivation (fa: {
  pname = "openmohaa";
  version = "0.52.0";

  src = fetchFromGitHub {
    owner = "openmoh";
    repo = "openmohaa";
    rev = "v${fa.version}";
    hash = "sha256-Q/GMFKLHAMf8QZ7XiVe3q3A+yeDFNymxMnDdZaRsr28=";
  };

  nativeBuildInputs = [ cmake pkg-config ];
  buildInputs = [
    # server
    SDL2
    openalSoft
    curl
    libogg
    libvorbis
    libopus

    # client
    freeglut
    libGL
    libXext
    libXxf86dga
    libXxf86vm
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
