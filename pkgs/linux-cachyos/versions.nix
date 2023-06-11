{
  # Matches "Add-extra-version-CachyOS.patch"
  suffix = "-cachyos";

  # pkgver from config's PKGBUILD
  linux.version = "6.3.7";
  linux.hash = "sha256-/jaXQ5lsUip7Rz6Z3Pj4iEe9XMiFRv07ekHZ/lpbl6k=";

  # latest commit from https://github.com/CachyOS/linux-cachyos/commits/master/linux-cachyos
  config.rev = "fff0431e2d9ce412df2f947808a5bc389325f8d6";
  config.hash = "sha256-OXcUgHfICKIsbIGsmO94b0PV6ECvWQxULHJmIlC5n/s=";

  # latest commit from https://github.com/CachyOS/kernel-patches/commits/master/6.3
  patches.rev = "f666e443cec83a73dad4fc41ebe1b997103f75f6";
  patches.hash = "sha256-+wMXOpzZ2yISwGXVSAFX/o75JvRNkGZxJnUE/T1E2js=";

  # search for git+https://github.com/cachyos/zfs.git in config's PKGBUILD
  zfs.rev = "893549d6259a6904b7c1ee58080eb72acc4ff7aa";
  zfs.hash = "sha256-t88f2GBeurx7ckwGCbHkC0detpgNS+Tfh13pF+FrRck=";
}
