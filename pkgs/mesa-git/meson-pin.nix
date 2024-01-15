# Waiting for nixpkgs#277403
{ final, nyxUtils, ... }:
final.meson.overrideAttrs (prevAttrs: with final; rec {
  version = "1.3.1";
  name = "${prevAttrs.pname}-${version}";
  src = fetchFromGitHub {
    owner = "mesonbuild";
    repo = "meson";
    rev = "refs/tags/${version}";
    hash = "sha256-KNNtHi3jx0MRiOgmluA4ucZJWB2WeIYdApfHuspbCqg=";
  };
  patches = nyxUtils.removeByBaseName
    "007-darwin-case-sensitivity.patch"
    prevAttrs.patches;
})
