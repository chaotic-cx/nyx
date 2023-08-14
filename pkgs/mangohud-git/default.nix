{ flakes, nyxUtils, prev, mangohud32, ... }:

nyxUtils.multiOverride prev.mangohud { inherit mangohud32; }
  (prevAttrs: rec {
    version = nyxUtils.gitToVersion src;
    src = flakes.mangohud-git-src;
    patches = [ ./preload-nix-workaround.patch ] ++
      (nyxUtils.removeByBaseName "preload-nix-workaround.patch"
        (nyxUtils.removeByURL "https://github.com/flightlessmango/MangoHud/commit/3f8f036ee8773ae1af23dd0848b6ab487b5ac7de.patch"
          prevAttrs.patches
        ));
    postPatch = (prevAttrs.postPatch or "") + ''
      substituteInPlace src/meson.build \
        --replace "run_command(['git', 'describe', '--tags', '--dirty=+']).stdout().strip()" \
          "'${src.lastModifiedDate}-${src.shortRev}'"
    '';
    # We bump it with flakes
    passthru = prevAttrs.passthru // { updateScript = null; };
  })
