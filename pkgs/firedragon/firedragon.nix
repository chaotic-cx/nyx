{ callPackage }:
let
  src = callPackage ./src.nix { };
in
rec {
  inherit (src) packageVersion firefox source source-firedragon;

  extraPatches = [ ];

  extraConfigureFlags = [
    "--allow-addon-sideload"
    "--disable-debug"
    "--with-app-basename=FireDragon"
    "--with-app-name=firedragon"
    "--with-branding=browser/branding/firedragon"
    "--with-distribution-id=org.garudalinux"
    "--with-unsigned-addon-scopes=app,system"
  ];

  # FireDragon builds on top of LibreWolf, therefore we can use mostly the same patches
  extraPostPatch = ''
    mkdir -p temp
    cp ${source}/assets/patches.txt temp
    sed -i 's&patches/librewolf-pref-pane.patch&&g' temp/patches.txt
    sed -i 's&patches/ui-patches/privacy-preferences.patch&&g' temp/patches.txt
    sed -i '/^$/d' temp/patches.txt

    while read patch_name; do
      echo "applying LibreWolf patch: $patch_name"
      patch -p1 < ${source}/$patch_name
    done <temp/patches.txt

    cp -r "${source-firedragon}/common/source_files/browser" .
    patch -p1 < ${source-firedragon}/common/patches/custom/add_firedragon_svg.patch
    patch -p1 < ${source-firedragon}/common/patches/custom/librewolf-pref-pane.patch
    patch -p1 < ${source-firedragon}/common/patches/custom/privacy-preferences.patch

    cp ${source}/assets/search-config.json services/settings/dumps/main/search-config.json
    sed -i '/MOZ_NORMANDY/ s/True/False/' browser/moz.configure
    sed -i '/MOZ_SERVICES_HEALTHREPORT/ s/True/False/' browser/moz.configure
  '';

  extraPrefsFiles = [ "${source-firedragon}/firedragon.cfg" ];

  extraPoliciesFiles = [ "${source-firedragon}/distribution/policies.json" ];

  extraPassthru = {
    firedragon = { inherit src extraPatches; };
    inherit extraPrefsFiles extraPoliciesFiles;
  };
}
