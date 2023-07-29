{ flakes, nyxUtils, prev, mangohud32, ... }:

nyxUtils.multiOverride prev.mangohud { inherit mangohud32; }
  (prevAttrs: rec {
    version = nyxUtils.gitToVersion src;
    src = flakes.mangohud-git-src;
    patches = [ ./preload-nix-workaround.patch ] ++
      (nyxUtils.removeByBaseName "preload-nix-workaround.patch" prevAttrs.patches);
    postPatch = (prevAttrs.postPatch or "") + ''
      substituteInPlace src/meson.build \
        --replace "run_command(['git', 'describe', '--tags', '--dirty=+']).stdout().strip()" \
          "'${src.lastModifiedDate}-${src.shortRev}'"
    '';
    # We bump it with flakes
    passthru = prevAttrs.passthru // { updateScript = null; };
  })
