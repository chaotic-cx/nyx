{ callPackage }:
let
  src = callPackage ./src.nix { };
in
rec {
  inherit (src) packageVersion floorp firedragon-common firedragon-settings;

  extraPatches = [ ];

  extraConfigureFlags = [
    "--allow-addon-sideload"
    "--disable-crashreporter"
    "--disable-debug"
    "--disable-debug-js-modules"
    "--disable-debug-symbols"
    "--disable-default-browser-agent"
    "--disable-gpsd"
    "--disable-necko-wifi"
    "--disable-rust-tests"
    "--disable-tests"
    "--disable-updater"
    "--disable-warnings-as-errors"
    "--disable-webspeech"
    "--enable-bundled-fonts"
    "--enable-jxl"
    "--enable-private-components"
    "--enable-proxy-bypass-protection"
    "--with-app-basename=FireDragon"
    "--with-app-name=firedragon"
    "--with-branding=browser/branding/firedragon"
    "--with-distribution-id=org.garudalinux"
    "--with-unsigned-addon-scopes=app,system"
  ];

  extraPostPatch = ''
    cp -r "${firedragon-common}/source_files/browser" .
    patch -p1 < ${firedragon-common}/patches/floorp/allow-ubo-private-mode.patch
    patch -p1 < ${firedragon-common}/patches/floorp/custom-ubo-assets-bootstrap-location.patch
    patch -p1 < ${firedragon-common}/patches/floorp/hide-passwordmgr.patch
    patch -p1 < ${firedragon-common}/patches/floorp/remove_addons.patch
    patch -p1 < ${firedragon-common}/patches/floorp/sed-patches/stop-undesired-requests.patch
    patch -p1 < ${firedragon-common}/patches/floorp/urlbarprovider-interventions.patch

    patch -p1 < ${firedragon-common}/patches/pref-pane/pref-pane-small.patch
    cp "${firedragon-common}/patches/pref-pane/category-firedragon.svg" browser/themes/shared/preferences/category-firedragon.svg
    cp "${firedragon-common}/patches/pref-pane/firedragon.css" browser/themes/shared/preferences/firedragon.css
    cp "${firedragon-common}/patches/pref-pane/firedragon.inc.xhtml" browser/components/preferences/firedragon.inc.xhtml
    cp "${firedragon-common}/patches/pref-pane/firedragon.js" browser/components/preferences/firedragon.js
    cat < "${firedragon-common}/patches/pref-pane/preferences.ftl" >> browser/locales/en-US/browser/preferences/preferences.ftl

    sed -i '/MOZ_CRASHREPORTER/ s/True/False/' browser/moz.configure
    sed -i '/MOZ_DATA_REPORTING/ s/True/False/' browser/moz.configure
    sed -i '/MOZ_NORMANDY/ s/True/False/' browser/moz.configure
    sed -i '/MOZ_REQUIRE_SIGNING/ s/True/False/' browser/moz.configure
    sed -i '/MOZ_SERVICES_HEALTHREPORT/ s/True/False/' browser/moz.configure
    sed -i '/MOZ_TELEMETRY_REPORTING/ s/True/False/' browser/moz.configure
  '';

  extraPrefsFiles = [ "${firedragon-settings}/firedragon.cfg" ];

  extraPoliciesFiles = [ "${firedragon-settings}/distribution/policies.json" ];

  extraPassthru = {
    firedragon = { inherit src extraPatches; };
    inherit extraPrefsFiles extraPoliciesFiles;
  };
}
