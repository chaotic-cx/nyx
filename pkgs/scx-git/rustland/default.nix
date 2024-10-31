{ scx
, rustPlatform
, scx-common
,
}:
scx.rustland.overrideAttrs {
  inherit (scx-common) src version;

  cargoDeps = rustPlatform.importCargoLock {
    lockFile = ./Cargo.lock;
  };
  postPatch = ''
    rm Cargo.toml Cargo.lock
    ln -fs ${./Cargo.lock} scheds/rust/scx_rustland/Cargo.lock
  '';
}
