# Waiting for nixpkgs#272823
{ final, ... }:
final.directx-headers.overrideAttrs (_prevAttrs: with final; rec {
  version = "1.611.0";
  src = fetchFromGitHub {
    owner = "microsoft";
    repo = "DirectX-Headers";
    rev = "v${version}";
    hash = "sha256-HG2Zj8hvsgv8oeSDp1eK+1A5bvFL6oQIh5mMFWOFsvk=";
  };
})
