{
  # "-${pkgsuffix}-${pkgrel}" from config's PKGBUILD
  suffix = "-cachyos-1";

  # pkgver from config's PKGBUILD
  linux.version = "6.3.3";
  linux.hash = "sha256-iXUhamzugnOQWGdY7WnRl0M2cJjR/F3VaUmHu1KeROU=";

  # latest commit from https://github.com/CachyOS/linux-cachyos/commits/master
  config.rev = "a88746d376aa0bf988aebe8e3d4b49663a8609d6";
  config.hash = "sha256-l80AjAAqyRV5SkAbKOeuyFa0imcs8vZtExI7eVeN9IE=";

  # latest commit from https://github.com/CachyOS/kernel-patches/commits/master/6.3
  patches.rev = "a1eae52fa8905e90c47a095131609c3f56505a5b";
  patches.hash = "sha256-TbdSnEZ0zGb+x3O8ulWoQ4cTP+pIb4mAC3YwAhoe2FE=";

  # search for git+https://github.com/cachyos/zfs.git in config's PKGBUILD
  zfs.rev = "ac18dc77f3703940682aecb442f4e58aa2c14f1a";
  zfs.hash = "sha256-wrMZYENs4hmrHXcSN4kYgntaDDs5IwOMeWWqUKortbw=";
}
