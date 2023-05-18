{
  # Matches "Add-extra-version-CachyOS.patch"
  suffix = "-cachyos";

  # pkgver from config's PKGBUILD
  linux.version = "6.3.3";
  linux.hash = "sha256-iXUhamzugnOQWGdY7WnRl0M2cJjR/F3VaUmHu1KeROU=";

  # latest commit from https://github.com/CachyOS/linux-cachyos/commits/master
  config.rev = "a88746d376aa0bf988aebe8e3d4b49663a8609d6";
  config.hash = "sha256-l80AjAAqyRV5SkAbKOeuyFa0imcs8vZtExI7eVeN9IE=";

  # latest commit from https://github.com/CachyOS/kernel-patches/commits/master/6.3
  patches.rev = "06db3a63ae49389aa24fc88793f525905e940d52";
  patches.hash = "sha256-6gPP0IhKZXWTmb0yWl5fiZbRXTnhZMrTMFe2w3RMhuI=";

  # search for git+https://github.com/cachyos/zfs.git in config's PKGBUILD
  zfs.rev = "ac18dc77f3703940682aecb442f4e58aa2c14f1a";
  zfs.hash = "sha256-wrMZYENs4hmrHXcSN4kYgntaDDs5IwOMeWWqUKortbw=";
}
