{
  prev,
  gitOverride,
  ...
}:

gitOverride (current: {
  nyxKey = "shadps4_git";
  prev = prev.shadps4;

  newInputs = {
    # TODO: We could use a xbyak_git
    renderdoc = null;
  };

  manifestPath = "pkgs/shadps4-git/manifest.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "shadps4-emu";
    repo = "shadPS4";
    fetchSubmodules = true;
  };

  postOverride = prevAttrs: {
    patches = [ ];
    nativeBuildInputs = (prevAttrs.nativeBuildInputs or [ ]) ++ [ prev.python3 ];
    cmakeFlags = (prevAttrs.cmakeFlags or [ ]) ++ [
      "-DSPDLOG_FMT_EXTERNAL=ON"
    ];
    postPatch = (prevAttrs.postPatch or "") + ''
      # fmt 12 no longer pulls in format.h via core.h
      if grep -q '#include <fmt/core.h>' src/emulator.cpp; then
        substituteInPlace "src/emulator.cpp" \
          --replace '#include <fmt/core.h>' '#include <fmt/format.h>'
      fi

      # glibc 2.42 no longer transitively provides <cstring>.
      # Inject it into files that use std::mem* / std::str* APIs but lack the include.
      find src -type f \( -name '*.cpp' -o -name '*.h' \) \
        -exec grep -qE 'std::mem(cpy|set|cmp|move)|std::str(cat|cmp|cpy|len|ncpy|str|chr|rchr|spn|cspn|pbrk|tok|coll|xfrm|error)' {} \; \
        -exec sh -c 'grep -q "^#include <cstring>" "$1" && exit 0; grep -q "^#include" "$1" && sed -i "0,/^#include/s|^#include|#include <cstring>\n&|" "$1" || sed -i "1i#include <cstring>" "$1"' _ {} \;

      # emulator.cpp uses std::round without including <cmath>.
      sed -i '0,/^#include/s|^#include|#include <cmath>\n&|' src/emulator.cpp
    '';

    # Generate COMMIT and SOURCE_DATE_EPOCH in prePatch (before nixpkgs's
    # postPatch uses $(cat COMMIT)). nixpkgs uses postFetch with leaveDotGit
    # because it pins a fixed immutable tag (v.0.13.0). We pin a git rev
    # which can become unstable if upstream cleans up, because git metadata
    # participates in the hash when leaveDotGit is set.
    prePatch = ''
      printf "${builtins.substring 0 8 current.rev}" > COMMIT
      echo "1970-01-01T00:00:00Z" > SOURCE_DATE_EPOCH
    '';
  };
})
