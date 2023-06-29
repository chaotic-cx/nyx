{ writeScript
, lib
, coreutils
, gnused
, gnugrep
, curl
, gnupg
, jq
, git
, nix-prefetch-git
, moreutils
, runtimeShell
, ...
}:

writeScript "update-librewolf" ''
  #!${runtimeShell}
  PATH=${lib.makeBinPath [ coreutils curl gnugrep gnupg gnused jq moreutils git nix-prefetch-git ]}
  set -euo pipefail

  latestTag=$(curl https://gitlab.com/api/v4/projects/librewolf-community%2Fbrowser%2Fsource/repository/tags?per_page=1 | jq -r .[0].name)
  echo "latestTag=$latestTag"

  srcJson=pkgs/firedragon/src.json
  localRev=$(jq -r .source.rev < $srcJson)
  echo "localRev=$localRev"

  if [ "$localRev" == "$latestTag" ]; then
    exit 0
  fi

  prefetchOut=$(mktemp)
  repoUrl=https://gitlab.com/librewolf-community/browser/source.git/
  nix-prefetch-git $repoUrl --quiet --rev $latestTag --fetch-submodules > $prefetchOut
  srcDir=$(jq -r .path < $prefetchOut)
  srcHash=$(jq -r .sha256 < $prefetchOut)

  ffVersion=$(<$srcDir/version)
  lwRelease=$(<$srcDir/release)
  lwVersion="$ffVersion-$lwRelease"
  echo "lwVersion=$lwVersion"
  echo "ffVersion=$ffVersion"
  if [ "$lwVersion" != "$latestTag" ]; then
    echo "error: Tag name does not match the computed LibreWolf version"
    exit 1
  fi

  _OLDHOME=$HOME
  _OLDGNUPGHOME=''${GNUPGHOME:-}

  HOME=$(mktemp -d)
  export GNUPGHOME=$(mktemp -d)
  gpg --receive-keys 14F26682D0916CDD81E37B6D61B7B526D98F0353

  mozillaUrl=https://archive.mozilla.org/pub/firefox/releases/

  curl --silent --show-error -o "$HOME"/shasums "$mozillaUrl$ffVersion/SHA512SUMS"
  curl --silent --show-error -o "$HOME"/shasums.asc "$mozillaUrl$ffVersion/SHA512SUMS.asc"
  gpgv --keyring="$GNUPGHOME"/pubring.kbx "$HOME"/shasums.asc "$HOME"/shasums

  ffHash=$(grep '\.source\.tar\.xz$' "$HOME"/shasums | grep '^[^ ]*' -o)
  echo "ffHash=$ffHash"

  jq ".source.rev = \"$latestTag\"" $srcJson |\
    jq ".source.sha256 = \"$srcHash\"" |\
    jq ".firefox.version = \"$ffVersion\"" |\
    jq ".firefox.sha512 = \"$ffHash\"" |\
    jq ".packageVersion = \"$lwVersion\"" |\
    sponge $srcJson

  HOME=$_OLDHOME
  if [ -n "$_OLDGNUPGHOME" ]; then export GNUPGHOME=$_OLDGNUPGHOME
  else unset GNUPGHOME
  fi

  git add $srcJson
  git commit -m "firedragon: $localRev -> $latestTag"
''
