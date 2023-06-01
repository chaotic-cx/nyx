{
  # Matches "Add-extra-version-CachyOS.patch"
  suffix = "-cachyos";

  # pkgver from config's PKGBUILD
  linux.version = "6.3.5";
  linux.hash = "sha256-9c1HjD2LkIq2Bq/R6VpPj3fnGGtKgoKSUdbmqq//gl4=";

  # latest commit from https://github.com/CachyOS/linux-cachyos/commits/master/linux-cachyos
  config.rev = "e64ec43be2ab67972fb84e942c3be52c9c78f5dd";
  config.hash = "sha256-q92B67rF82us4fnVxyck7KgriQwNVyDIcVIZnXDLB5I=";

  # latest commit from https://github.com/CachyOS/kernel-patches/commits/master/6.3
  patches.rev = "cf0d7cecefc55a8a9332927974b863462731e4fa";
  patches.hash = "sha256-xbWe8NKV/h96GHUsnimdaPmaF1TBHSmw4evcWVUmMB0=";

  # search for git+https://github.com/cachyos/zfs.git in config's PKGBUILD
  zfs.rev = "ac18dc77f3703940682aecb442f4e58aa2c14f1a";
  zfs.hash = "sha256-wrMZYENs4hmrHXcSN4kYgntaDDs5IwOMeWWqUKortbw=";
}
