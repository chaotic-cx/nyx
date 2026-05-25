{
  final,
  prev,
  gitOverride,
  ...
}:

gitOverride {
  newInputs = with final; {
    wayland-scanner = wayland-scanner_git;
  };

  nyxKey = "wayland_git";
  prev = prev.wayland;

  versionNyxPath = "pkgs/wayland-git/version.json";
  fetcher = "fetchFromGitLab";
  fetcherData = {
    domain = "gitlab.freedesktop.org";
    owner = "wayland";
    repo = "wayland";
  };

  postOverride = prevAttrs: {
    patches = [ ];

    nativeBuildInputs = prevAttrs.nativeBuildInputs or [ ] ++ [ final.mdbook ];

    # Create a wrapper for xmlto to ensure --skip-validation is used
    # This is a temporary fix for XML validation errors in documentation generation
    # Upstream re-enabled validation with "doc: validate doc XML again" commit
    # See: https://gitlab.freedesktop.org/wayland/wayland
    # TODO: Remove this fix when upstream properly fixes the XML validation errors
    preConfigure = (prevAttrs.preConfigure or "") + ''
            # Create a wrapper script for xmlto that adds --skip-validation
            mkdir -p $TMPDIR/bin
            cat > $TMPDIR/bin/xmlto << 'EOF'
      #!/bin/sh
      exec ${final.xmlto}/bin/xmlto --skip-validation "$@"
      EOF
            chmod +x $TMPDIR/bin/xmlto
            export PATH="$TMPDIR/bin:$PATH"
    '';
  };
}
