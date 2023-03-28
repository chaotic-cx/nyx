{ attr
, fetchFromGitHub
, fetchFromGitLab
, lib
, libevdev
, libxkbcommon
, meson
, ninja
, pkg-config
, protobuf
, protobufc
, python3
, python3Packages
, stdenv
, systemd
}:
let
  munit = fetchFromGitHub {
    owner = "nemequ";
    repo = "munit";
    rev = "fbbdf1467eb0d04a6ee465def2e529e4c87f2118";
    hash = "sha256-qm30C++rpLtxBhOABBzo+6WILSpKz2ibvUvoe8ku4ow=";
  };
in
stdenv.mkDerivation rec {
  pname = "libei";
  version = "0.4.1";

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    owner = "libinput";
    repo = "libei";
    rev = version;
    hash = "sha256-wjzzOU/wvs4QeRCQMH56TARONx+LjYFVMHgWWM/XOs4=";
  };

  buildInputs = [ libevdev libxkbcommon protobuf protobufc systemd ];
  nativeBuildInputs = [ attr meson ninja pkg-config python3 ] ++
    (with python3Packages; [ pytest python-dbusmock ]);

  postPatch = ''
    ln -s "${munit}" ./subprojects/munit
  '';

  meta = with lib; {
    description = "Library for Emulated Input";
    homepage = "https://gitlab.freedesktop.org/libinput/libei";
    license = licenses.mit;
    maintainers = [ maintainers.pedrohlc ];
    platforms = platforms.linux;
  };
}
