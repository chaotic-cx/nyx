# Credits going to federicoschonborn, taken from NUR and adapted to -git
{ cmake
, fetchFromGitHub
, git
, lib
, nyxUtils
, pkg-config
, stdenv
, enableLibpci ? false
, pciutils
, enableVulkan ? false
, vulkan-loader
, enableWayland ? false
, libffi
, wayland
, enableXcb ? false
, enableXrandr ? false
, enableX11 ? false
, xorg
, enableGio ? false
, glib
, libselinux
, libsepol
, pcre16
, pcre2
, utillinux
, enableDconf ? false
, dconf
, enableDbus ? false
, dbus
, enableXfconf ? false
, xfce
, enableSqlite3 ? false
, sqlite
, enableRpm ? false
, rpm
, enableImagemagick7 ? false
, imagemagick
, enableZlib ? false
, zlib
, enableChafa ? false
, chafa
, enableEgl ? false
, libGL
, enableGlx ? false
, libglvnd
, enableMesa ? false
, mesa_drivers
, enableOpencl ? false
, ocl-icd
, opencl-headers
, enableLibcjson ? false
, cjson
, enableLibnm ? false
, networkmanager
, enableFreetype ? false
, freetype
, enablePulse ? false
, libpulseaudio
,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "fastfetch";
  version = "unstable-2023-07-01";

  src = fetchFromGitHub {
    owner = "LinusDierheimer";
    repo = "fastfetch";
    rev = "1f799d16c99c7b245a23e6328b1312003d5635c0";
    hash = "sha256-I9HJEfXcFTKtG1PCCFMGJtSXh7mhDyRmm0oW9vi9Tjo=";
  };

  nativeBuildInputs = [
    cmake
    git
    pkg-config
  ];

  buildInputs =
    [ ]
    ++ lib.optionals enableChafa [ chafa ]
    ++ lib.optionals enableDbus [ dbus ]
    ++ lib.optionals enableDconf [ dconf ]
    ++ lib.optionals enableEgl [ libGL ]
    ++ lib.optionals enableFreetype [ freetype ]
    ++ lib.optionals enableGio [ glib libselinux libsepol pcre16 pcre2 utillinux ]
    ++ lib.optionals enableGlx [ libglvnd ]
    ++ lib.optionals enableImagemagick7 [ imagemagick ]
    ++ lib.optionals enableLibcjson [ cjson ]
    ++ lib.optionals enableLibnm [ networkmanager ]
    ++ lib.optionals enableLibpci [ pciutils ]
    ++ lib.optionals enableMesa [ mesa_drivers.dev ]
    ++ lib.optionals enableOpencl [ ocl-icd opencl-headers ]
    ++ lib.optionals enablePulse [ libpulseaudio ]
    ++ lib.optionals enableRpm [ rpm ]
    ++ lib.optionals enableSqlite3 [ sqlite ]
    ++ lib.optionals enableVulkan [ vulkan-loader ]
    ++ lib.optionals enableWayland [ libffi wayland ]
    ++ lib.optionals enableX11 [ xorg.libX11 ]
    ++ lib.optionals enableXcb [ xorg.libXau xorg.libXdmcp xorg.libxcb ]
    ++ lib.optionals enableXfconf [ xfce.xfconf ]
    ++ lib.optionals enableXrandr [ xorg.libXext xorg.libXrandr ]
    ++ lib.optionals enableZlib [ zlib ];

  cmakeFlags = [
    "-DTARGET_DIR_ROOT=${placeholder "out"}"
  ];

  meta = with lib; {
    description = "Like neofetch, but much faster because written in C";
    homepage = "https://github.com/LinusDierheimer/fastfetch";
    changelog = "https://github.com/LinusDierheimer/fastfetch/blob/dev/CHANGELOG.md";
    license = licenses.mit;
    maintainers = with maintainers; [ dr460nf1r3 federicoschonborn ];
  };
})
