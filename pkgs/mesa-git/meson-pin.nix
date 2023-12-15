# Waiting for nixpkgs#268583
{ final, nyxUtils, ... }:
final.meson.overrideAttrs (prevAttrs: with final; rec {
  version = "1.3.0";
  src = fetchFromGitHub {
    owner = "mesonbuild";
    repo = "meson";
    rev = "refs/tags/${version}";
    hash = "sha256-Jt3PWnbv/8P6Rvf3E/Yli2vdtfgx3CmsW+jlc9CK5KA=";
  };
  patches = nyxUtils.removeByURL
    "https://github.com/mesonbuild/meson/commit/d5252c5d4cf1c1931fef0c1c98dd66c000891d21.patch"
    prevAttrs.patches;
})
