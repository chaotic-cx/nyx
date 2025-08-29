{
  scx,
  scx-common,
  rustPlatform,
}:

(scx.rustscheds.overrideAttrs (_prevAttrs: {
  inherit (scx-common) version src patches;
  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit (scx-common) src;
    hash = scx-common.cargoHash;
  };
}))
