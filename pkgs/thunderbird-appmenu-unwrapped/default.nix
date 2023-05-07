{ final, inputs, prev, ... }:
let
  unity-menubar = builtins.fetchurl {
    url = "https://aur.archlinux.org/cgit/aur.git/plain/unity-menubar.patch?h=thunderbird-appmenu";
    sha256 = "10srnaj55vz13il0niyfv3yg0jg1bc9wkwzkplhil7210lrwm2az";
  };
in
prev.thunderbird-unwrapped.overrideAttrs (prevAttrs: rec  {
  patches = [ unity-menubar ];
})
