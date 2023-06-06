{ final, inputs, nyxUtils, prev, qttools, ... }:

prev.barrier.overrideAttrs (pa: {
  pname = "input-leap";
  src = inputs.input-leap-git-src;
  version = nyxUtils.gitToVersion inputs.input-leap-git-src;
  nativeBuildInputs = pa.nativeBuildInputs ++ (with final; [
    pkg-config
    gtest
    ghc_filesystem
  ]);
  buildInputs = pa.buildInputs ++ [
    final.libei
    final.libportal
    qttools
  ];
  patches = [ ];
  cmakeFlags = [
    "-DINPUTLEAP_USE_EXTERNAL_GTEST=ON"
    "-DINPUTLEAP_BUILD_LIBEI=ON"
  ];
  postFixup = ''
    substituteInPlace "$out/share/applications/input-leap.desktop" --replace "Exec=input-leap" "Exec=$out/bin/input-leap"
  '';
})
