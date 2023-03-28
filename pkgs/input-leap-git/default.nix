{ barrier
, ghc_filesystem
, gtest
, input-leap-git-src
, libei
, libportal
, pkg-config
, qttools
}:
barrier.overrideAttrs (pa: {
  pname = "input-leap";
  src = input-leap-git-src;
  nativeBuildInputs = pa.nativeBuildInputs ++ [
    pkg-config
    gtest
    ghc_filesystem
    libei
  ];
  buildInputs = pa.buildInputs ++ [
    libportal
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
