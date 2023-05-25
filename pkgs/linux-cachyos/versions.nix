{
  # Matches "Add-extra-version-CachyOS.patch"
  suffix = "-cachyos";

  # pkgver from config's PKGBUILD
  linux.version = "6.3.4";
  linux.hash = "sha256-2GJ1KO1rOuYH0Ase9aRuDnBRrkCyhf1OgvT/C7craOg=";

  # latest commit from https://github.com/CachyOS/linux-cachyos/commits/master
  config.rev = "2eedd656d8bbef6fe7deac8d1daf2af685553615";
  config.hash = "sha256-22pBAYR1EqAj1tAgAmVK6i2hWgYbvSD/cvYwS0v7FAU=";

  # latest commit from https://github.com/CachyOS/kernel-patches/commits/master/6.3
  patches.rev = "1f326f7983982f0c23f46cc14368363e3bcfbd8c";
  patches.hash = "sha256-H2LDC5zQhMvPIY/jOV7aN7OW16yMSVgHf1XsOGdzF2E=";

  # search for git+https://github.com/cachyos/zfs.git in config's PKGBUILD
  zfs.rev = "ac18dc77f3703940682aecb442f4e58aa2c14f1a";
  zfs.hash = "sha256-wrMZYENs4hmrHXcSN4kYgntaDDs5IwOMeWWqUKortbw=";
}
