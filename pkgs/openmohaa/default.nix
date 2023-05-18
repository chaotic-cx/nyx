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
  version = "0.50";

  src = fetchFromGitHub {
    owner = "openmoh";
    repo = "openmohaa";
    rev = fa.version;
    hash = "sha256-nOJv9nNR2erdQS+MCUMWjZm5VqYzfdpsLievPZmj3ic=";
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
    "-DWITH_CLIENT=on"
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
