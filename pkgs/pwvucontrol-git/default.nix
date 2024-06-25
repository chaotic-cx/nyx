{ final, prev, gitOverride, pwvucontrolPins, ... }:

gitOverride {
  nyxKey = "pwvucontrol_git";
  prev = prev.pwvucontrol;

  versionNyxPath = "pkgs/pwvucontrol-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "saivert";
    repo = "pwvucontrol";
  };

  withCargoDeps = final.rustPlatform.importCargoLock {
    lockFile = ./Cargo.lock;
    outputHashes = pwvucontrolPins;
  };
}
