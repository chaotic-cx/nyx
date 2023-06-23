{
  # Matches "Add-extra-version-CachyOS.patch"
  suffix = "-cachyos";

  # pkgver from config's PKGBUILD
  linux.version = "6.3.9";
  linux.hash = "sha256-QezyE5mxerhRY3ULoiNH0JtU+gmbgLY9Di7wBmEpsT4=";

  # latest commit from https://github.com/CachyOS/linux-cachyos/commits/master/linux-cachyos
  config.rev = "42a11163665d0ff8dff6d203fabf9158f26f4680";
  config.hash = "sha256-D5sJ14hfo7E8ky4kwGmNbqPXvahbdYCPDHHk2yi12WQ=";

  # latest commit from https://github.com/CachyOS/kernel-patches/commits/master/6.3
  patches.rev = "fee3f21363842f7e559a64fe36fabe38be569d3e";
  patches.hash = "sha256-/r4GxD0ssRhDfcy2Xb5zNKblucTDg4RCietpyTJX8SI=";

  # search for git+https://github.com/cachyos/zfs.git in config's PKGBUILD
  zfs.rev = "893549d6259a6904b7c1ee58080eb72acc4ff7aa";
  zfs.hash = "sha256-t88f2GBeurx7ckwGCbHkC0detpgNS+Tfh13pF+FrRck=";
}
