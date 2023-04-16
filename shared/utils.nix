{ lib }:
rec {
  dropN = n: list: lib.lists.take (builtins.length list - n) list;

  gitToVersion = src: "unstable-${src.lastModifiedDate}-${src.shortRev}";

  gitOverride = src: drv:
    drv.overrideAttrs (_: {
      version = gitToVersion src;
      inherit src;
    });
}
