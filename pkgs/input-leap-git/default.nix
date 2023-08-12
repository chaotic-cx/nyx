{ final, flakes, nyxUtils, ... }:

final.input-leap.overrideAttrs (pa: {
  src = flakes.input-leap-git-src;
  version = nyxUtils.gitToVersion flakes.input-leap-git-src;
  nativeBuildInputs = pa.nativeBuildInputs ++ (with final; [
    gtest
    ghc_filesystem
  ]);
  buildInputs = pa.buildInputs ++ (with final; [
    libuuid
  ]);
  cmakeFlags = [
    "-DINPUTLEAP_USE_EXTERNAL_GTEST=ON"
  ];
})
