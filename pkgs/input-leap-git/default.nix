{ final, flakes, nyxUtils, ... }:

final.input-leap.overrideAttrs (prevAttrs: {
  src = flakes.input-leap-git-src;
  version = nyxUtils.gitToVersion flakes.input-leap-git-src;
  nativeBuildInputs = prevAttrs.nativeBuildInputs ++ (with final; [
    gtest
    ghc_filesystem
  ]);
  buildInputs = prevAttrs.buildInputs ++ (with final; [
    libuuid
  ]);
  cmakeFlags = [
    "-DINPUTLEAP_USE_EXTERNAL_GTEST=ON"
  ];
})
