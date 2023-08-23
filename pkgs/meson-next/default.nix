{ final, prev, nyxUtils, ... }:

prev.meson.overrideAttrs (prevAttrs: rec {
  version = "1.2.0";
  src = final.fetchFromGitHub {
    owner = "mesonbuild";
    repo = "meson";
    rev = "refs/tags/${version}";
    hash = "sha256-bJAmkE+sL9DqKpcjZdBf4/z9lz+m/o0Z87hlAwbVbTY=";
  };
  patches = nyxUtils.removeByBaseName "darwin-case-sensitive-fs.patch" pa.patches;
})
