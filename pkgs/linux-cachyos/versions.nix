{
  # Matches "Add-extra-version-CachyOS.patch"
  suffix = "-cachyos";

  # pkgver from config's PKGBUILD
  linux.version = "6.3.8";
  linux.hash = "sha256-QyPUISUOLkRMNdNvSqjdtWWR3twlxo01nRnE753SCVU=";

  # latest commit from https://github.com/CachyOS/linux-cachyos/commits/master/linux-cachyos
  config.rev = "d48704275107207a76c06f74cdc6d58abb71ea78";
  config.hash = "sha256-wb1/WEmHoxA177AnNG6qSxf+ozxM6A4Z59gD4yc//vE=";

  # latest commit from https://github.com/CachyOS/kernel-patches/commits/master/6.3
  patches.rev = "1cea10484e68e8c7c21e8fcc6015355050b3f744";
  patches.hash = "sha256-vMk/IkXDS0RR4FbvPXNqvoxwGAgNn5DW7cZVONu6Z3o=";

  # search for git+https://github.com/cachyos/zfs.git in config's PKGBUILD
  zfs.rev = "893549d6259a6904b7c1ee58080eb72acc4ff7aa";
  zfs.hash = "sha256-1ja5dghigsaxhzgy8jqdk2v5wiqbwjqhj1jcf9xvrfjyc3c1zkxp";
}
