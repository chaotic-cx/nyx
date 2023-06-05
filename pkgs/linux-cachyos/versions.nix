{
  # Matches "Add-extra-version-CachyOS.patch"
  suffix = "-cachyos";

  # pkgver from config's PKGBUILD
  linux.version = "6.3.6";
  linux.hash = "sha256-emofDfoL9/RfnUp7QJMVzzImeFCtq02wM6F94DIKJO8=";

  # latest commit from https://github.com/CachyOS/linux-cachyos/commits/master/linux-cachyos
  config.rev = "8180543ca95e9353464f90c5f9975add33f5fe01";
  config.hash = "sha256-t9KNEVQhup9oLXly+4UV0HoSmouI4A5lPLGL81Gzask=";

  # latest commit from https://github.com/CachyOS/kernel-patches/commits/master/6.3
  patches.rev = "229660f0c4cf6efa861c5a58718376453492c9c2";
  patches.hash = "sha256-mpW88nZ5nxQlEHaQI5pNmA8SOg2E9VoTl9vq840901k=";

  # search for git+https://github.com/cachyos/zfs.git in config's PKGBUILD
  zfs.rev = "2582dbec90ac8639dcecaf5ffc95040e759a67d1";
  zfs.hash = "sha256-VnS2L6EmzvOqXuXJGgFmKp4cprpRdhb6kZHBg1G7pNk=";
}
