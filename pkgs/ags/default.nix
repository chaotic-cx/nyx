{
  pkgs,
  lib,
  buildGoModule,
  fetchFromGitHub,
  extraPackages ? [],
  ...
}: let
  inherit (builtins) replaceStrings readFile;

  current = lib.trivial.importJSON ./version.json;
  agsSrc = fetchFromGitHub {
    inherit (current) rev hash;
    owner = "Aylur";
    repo = "ags";
  };

  version = replaceStrings ["\n"] [""] (readFile "${agsSrc}/version");
  pname = "ags";

  buildInputs =
    extraPackages
    ++ (with pkgs; [
      glib
      astal_io
      astal3
      astal4
      gobject-introspection # needed for type generation
    ]);

  bins = with pkgs; [
    gjs
    nodejs
    dart-sass
    blueprint-compiler
    astal_io # FIXME: should not be needed after the astal commands are properly implemented using dbus in astal.go
  ];

  girDirs = let
    # gir files are usually in `dev` output.
    # `propagatedBuildInputs` are also available in the gjs runtime
    # so we also want to generate types for these.
    depsOf = pkg:
      [(pkg.dev or pkg)]
      ++ (map depsOf (pkg.propagatedBuildInputs or []));
  in
    pkgs.symlinkJoin {
      name = "gir-dirs";
      paths = lib.flatten (map depsOf buildInputs);
    };
in
  buildGoModule {
    inherit pname version buildInputs;

    src = agsSrc;

    vendorHash = "sha256-Pw6UNT5YkDVz4HcH7b5LfOg+K3ohrBGPGB9wYGAQ9F4=";
    proxyVendor = true;

    nativeBuildInputs = with pkgs; [
      wrapGAppsHook
      gobject-introspection
      installShellFiles
    ];

    preFixup = ''
      gappsWrapperArgs+=(
        --prefix EXTRA_GIR_DIRS : "${girDirs}/share/gir-1.0"
        --prefix PATH : "${lib.makeBinPath (bins ++ extraPackages)}"
      )
    '';

    postInstall = ''
      installShellCompletion \
        --cmd ags \
        --bash <($out/bin/ags completion bash) \
        --fish <($out/bin/ags completion fish) \
        --zsh <($out/bin/ags completion zsh)
    '';

    ldflags = [
      "-X main.astalGjs=${pkgs.astal_gjs}"
      "-X main.gtk4LayerShell=${pkgs.gtk4-layer-shell}/lib/libgtk4-layer-shell.so"
    ];

    meta = {
      homepage = "https://github.com/Aylur/ags";
      description = "Scaffolding CLI tool for Astal+TypeScript projects";
      license = lib.licenses.gpl3Plus;
      mainProgram = "ags";
      platforms = lib.platforms.linux;
    };
  }
