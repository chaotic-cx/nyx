{
  # "-${pkgsuffix}-${pkgrel}" from config's PKGBUILD
  suffix = "-cachyos-1";

  # pkgver from config's PKGBUILD
  linux.version = "6.3.2";
  linux.hash = "sha256-thLs8oLKP3mJ/22fOQgoM7fcLVIsuWmgUzTTYU6cUyg=";

  # latest commit from https://github.com/CachyOS/linux-cachyos/commits/master
  config.rev = "2edd239e20f2fb852a0bc962f48c1d394acc0a3d";
  config.hash = "sha256-s2EYR77XuWM1O4IaoY7XdffGZTG1qWnJGofBQWn5LGc=";

  # latest commit from https://github.com/CachyOS/kernel-patches/commits/master/6.3
  patches.rev = "d2b92b14e924b821d9ec8dea3f947f46e061dd88";
  patches.hash = "sha256-aDhYSryGU/S099EUPcX3O/r/JjIe7BbpkZonBM8ARfg=";

  # search for git+https://github.com/cachyos/zfs.git in config's PKGBUILD
  zfs.rev = "ac18dc77f3703940682aecb442f4e58aa2c14f1a";
  zfs.hash = "sha256-wrMZYENs4hmrHXcSN4kYgntaDDs5IwOMeWWqUKortbw=";
}
