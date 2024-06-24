# Taken from: https://github.com/NixOS/nixpkgs/blob/c00d587b1a1afbf200b1d8f0b0e4ba9deb1c7f0e/pkgs/tools/package-management/nix-top/default.nix
# SamuelDR left Nixpkgs and took his repos with him.
# Thankfully nixpkgs will still have it cached!

{ stdenv
, lib
, fetchFromGitHub
, ruby
, makeWrapper
, getent               # /etc/passwd
, ncurses              # tput
, binutils-unwrapped   # strings
, coreutils
, findutils
}:

# No gems used, so mkDerivation is fine.
let
  additionalPath = lib.makeBinPath [ getent ncurses binutils-unwrapped coreutils findutils ];
in
stdenv.mkDerivation rec {
  pname = "nix-top";
  version = "0.3.0";

  src = (fetchFromGitHub {
    owner = "samueldr";
    repo = "nix-top";
    rev = "v${version}";
    sha256 = "sha256-w/TKzbZmMt4CX2KnLwPvR1ydp5NNlp9nNx78jJvhp54=";
  });

  nativeBuildInputs = [
    makeWrapper
  ];

  buildInputs = [
    ruby
  ];

  installPhase = ''
    mkdir -p $out/libexec/nix-top
    install -D -m755 ./nix-top $out/bin/nix-top
    wrapProgram $out/bin/nix-top \
      --prefix PATH : "$out/libexec/nix-top:${additionalPath}"
  '' + lib.optionalString stdenv.isDarwin ''
    ln -s /bin/stty $out/libexec/nix-top
  '';

  meta = with lib; {
    description = "Tracks what nix is building";
    homepage = "https://github.com/samueldr/nix-top";
    license = licenses.mit;
    maintainers = [];
    platforms = platforms.linux ++ platforms.darwin ++ platforms.freebsd;
    mainProgram = "nix-top";
  };
}
