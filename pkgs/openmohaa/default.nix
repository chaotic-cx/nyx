{ lib
, callPackage
, llvmPackages_15
, fetchFromGitHub
, pkg-config
, cmake
, SDL2
, openal
, bison
, curl
, flex
, libogg
, libvorbis
, libopus
, openmohaaVersion
}:

llvmPackages_15.stdenv.mkDerivation {
  pname = "openmohaa";
  inherit (openmohaaVersion) version;

  src = fetchFromGitHub {
    owner = "openmoh";
    repo = "openmohaa";
    rev = "v${openmohaaVersion.version}";
    inherit (openmohaaVersion) hash;
  };

  nativeBuildInputs = [ cmake pkg-config bison flex ];
  buildInputs = [
    SDL2
    curl
    libogg
    libvorbis
    libopus
    openal
  ];

  cmakeFlags = [
    "-DWITH_CLIENT=1"
    "-DUSE_INTERNAL_LIBS=0"
    "-DUSE_FREETYPE=1"
    "-DUSE_OPENAL_DLOPEN=0"
    "-DUSE_CURL_DLOPEN=0"
  ];

  hardeningDisable = [ "format" ];

  enableParallelBuilding = true;

  passthru.updateScript = callPackage ./update.nix { };

  meta = with lib; {
    homepage = "https://github.com/openmoh/openmohaa";
    description = "Open re-implementation of Medal of Honor: Allied Assault";
    license = licenses.gpl2Only;
    platforms = platforms.linux;
    maintainers = with maintainers; [ pedrohlc ];
  };
}
