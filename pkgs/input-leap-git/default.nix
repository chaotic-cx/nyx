{ final, flakes, nyxUtils, prev, qttools, ... }:

prev.barrier.overrideAttrs (pa: {
  pname = "input-leap";
  src = flakes.input-leap-git-src;
  version = nyxUtils.gitToVersion flakes.input-leap-git-src;
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
  meta = pa.meta // {
    description = "Input-leap is KVM software forked from Symless's synergy 1.9 codebase.";
    homepage = "https://github.com/input-leap/input-leap";
  };
})
