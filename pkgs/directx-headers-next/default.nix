{ final, prev, ... }:

prev.directx-headers.overrideAttrs (_: rec {
  version = "1.610.0";
  src = final.fetchFromGitHub {
    owner = "microsoft";
    repo = "DirectX-Headers";
    rev = "v${version}";
    hash = "sha256-lPYXAMFSyU3FopWdE6dDRWD6sVKcjxDVsTbgej/T2sk=";
  };
})
