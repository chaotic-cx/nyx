{
  # Matches "Add-extra-version-CachyOS.patch"
  suffix = "-cachyos";

  # pkgver from config's PKGBUILD
  linux.version = "6.4";
  linux.hash = "sha256-j6BYjwws7KRMrHeg45ukjJ8AprncaXYcAqXT76yNp/M=";

  # latest commit from https://github.com/CachyOS/linux-cachyos/commits/master/linux-cachyos
  config.rev = "b8fc9c26a208bce373c656a2ac95a66022ee31b4";
  config.hash = "sha256-V9WG33zsta7McjqMAh6sTVb/N11H0nRRf5ajRVVr5Uc=";

  # latest commit from https://github.com/CachyOS/kernel-patches/commits/master/6.3
  patches.rev = "2dadc879ebcc27defa7abea41348691212edcd63";
  patches.hash = "sha256-ePgBb9BugyjbHhv7tkpvHaq691vw6PZ3JOdknaDRs68=";

  # search for git+https://github.com/cachyos/zfs.git in config's PKGBUILD
  zfs.rev = "f9a2d94c957d0660ad1f4cfbb0a909eb8e6086df";
  zfs.hash = "sha256-XCbFDlxowkmKDv71u00+FwBukqmMBsmY7p0BDe+IWWM=";
}
