pkgs: with pkgs; {
  # ArchLinux's core skipping efi-related, fs-related, kernel-related, bootloaders,
  #   text-editors, and network managers. Last synced 2023-11-21
  inherit acl libargon2 attr audit bash binutils coreutils bison brotli bzip2 cracklib
    cryptsetup curl dash db dbus debugedit dialog diffutils elfutils expat file findutils
    flex gawk gcc gdbm gettext glib glibc gpm gnutls gpgme gmp gnugrep groff guile gzip
    hwdata iana-etc icu inetutils iproute2 iptables iputils jansson jfsutils json_c kbd
    keyutils kmod krb5 ldns lemon less libaio libarchive libcap libedit libelf libevent
    libffi libgccjit libgcrypt libgpg-error libgssglue libidn2 inih isl libksba
    libmicrohttpd libmnl libmpc libnetfilter_conntrack libnfnetlink libnftnl
    libnghttp2 libnl libnsl libpcap libpipeline libpsl gsasl libseccomp
    libsecret libssh2 libtasn1 libtirpc libtool libunistring libusb libverto;
  inherit libxcrypt libxml2 links2 logrotate libgcc lz4 lzo m4 gnumake man-db mdadm
    minizip mlocate mpfr ncurses nettools npth nspr nss openssl p11-kit patch pciutils
    pcre pcre2 perl python3 readline rpcbind gnused sqlite gnutar texinfo tzdata
    util-linux which xz zlib zstd;

  recurseForDerivations = true;
}
