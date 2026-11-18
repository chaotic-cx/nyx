{
  callPackage,
  mkProtonBinDerivation,
  lib,
  fetchzip,
  # Required
  manifestFilename,
  owner,
  repo,
  # Optional
  withUpdateScript ? true,
  toolTitle ? null,
  toolArch ? "x86_64",
  toolName ? "${tarballPrefix}${releaseVersion}-${toolArch}",
  tarballPrefix ? "",
  tarballSuffix ? "",
  releasePrefix ? "proton-",
  releaseSuffix ? "",
  version ? lib.trivial.importJSON ./${manifestFilename},
  releaseVersion ? "${releasePrefix}${version.base}-${version.release}${releaseSuffix}",
  homepage ? "https://github.com/${owner}/${repo}",
  url ? "${homepage}/releases/download/${releaseVersion}/${tarballPrefix}${releaseVersion}${tarballSuffix}",
}:

mkProtonBinDerivation {
  pname = repo;
  version = "${version.base}.${version.release}";
  steamDisplayName = if toolTitle != null then toolTitle else toolName;

  variants.x86_64-linux = {
    inherit toolName;
    src = fetchzip {
      inherit url;
      inherit (version) hash;
      stripRoot = true;
    };
  };

  passthru =
    if withUpdateScript then
      {
        updateScript = callPackage ./update.nix {
          inherit
            tarballPrefix
            tarballSuffix
            releasePrefix
            releaseSuffix
            manifestFilename
            owner
            repo
            ;
        };
      }
    else
      { };

  meta = with lib; {
    inherit homepage;
    description = "Compatibility tool for Steam Play based on Wine and additional components (patched and built by ${owner})";
    license = licenses.bsd3;
    maintainers = with maintainers; [
      pedrohlc
    ];
  };
}
