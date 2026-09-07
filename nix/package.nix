{ lib
, stdenv
, makeWrapper
, python3
, qt5
, qt6
, acpi
, adw-gtk3
, alsa-utils
, bc
, bluez
, brightnessctl
, ddcutil
, cava
, cliphist
, easyeffects
, fastfetch
, fd
, ffmpeg
, file
, gpu-screen-recorder
, grim
, imagemagick
, inotify-tools
, iw
, jq
, kitty
, libnotify
, lm_sensors
, matugen
, nautilus
, networkmanager
, pamixer
, pavucontrol
, pciutils
, playerctl
, power-profiles-daemon
, psmisc
, ripgrep
, satty
, slurp
, socat
, util-linux
, wf-recorder
, wget
, wireplumber
, wl-clipboard
, wl-gammarelay-rs
, wmctrl
, xdg-desktop-portal-gtk
, zbar
, quickshell
, libpulseaudio
, pipewire
, ...
}:
let
  pname = "kairo";
  version = lib.strings.trim (builtins.readFile ../version.txt);
  pythonEnv = python3.withPackages (ps: [ ps.websockets ]);
  pathDeps = [
    acpi
    alsa-utils
    bc
    bluez
    brightnessctl
    ddcutil
    cava
    cliphist
    easyeffects
    fastfetch
    fd
    ffmpeg
    file
    gpu-screen-recorder
    grim
    imagemagick
    inotify-tools
    iw
    jq
    kitty
    libnotify
    lm_sensors
    matugen
    nautilus
    networkmanager
    pamixer
    pavucontrol
    pciutils
    playerctl
    power-profiles-daemon
    psmisc
    pythonEnv
    ripgrep
    satty
    slurp
    socat
    util-linux
    wf-recorder
    wget
    wireplumber
    wl-clipboard
    wl-gammarelay-rs
    wmctrl
    xdg-desktop-portal-gtk
    zbar
    quickshell
  ];
  qtDeps = [
    quickshell
    qt6.qtwayland
    qt6.qtmultimedia
    qt6.qt5compat
    qt6.qtwebsockets
  ];
  qmlImportPath = lib.concatMapStringsSep ":" (pkg: "${pkg}/lib/qt-6/qml") qtDeps;
  qtPluginPath = lib.concatMapStringsSep ":" (pkg: "${pkg}/lib/qt-6/plugins") qtDeps;
in
stdenv.mkDerivation (finalAttrs: {
  inherit pname version;
  src = lib.fileset.toSource {
    root = ../.;
    fileset = lib.fileset.unions (
      map (p: ../. + "/${p}") [ "bin" "src" "config" "compositors" "version.txt" "LICENSE.md" "UPSTREAM.md" "README.md" "CHANGELOG.md" ]
    );
  };
  nativeBuildInputs = [ makeWrapper qt6.wrapQtAppsHook ];
  buildInputs = qtDeps ++ [ libpulseaudio pipewire ];
  dontConfigure = true;
  dontBuild = true;
  dontWrapQtApps = true;
  installPhase = ''
    runHook preInstall
    mkdir -p "$out/bin" "$out/share/${finalAttrs.pname}"
    cp -r src/. "$out/share/${finalAttrs.pname}/"
    cp -r config "$out/share/${finalAttrs.pname}/config"
    cp version.txt "$out/share/${finalAttrs.pname}/version.txt"
    find "$out/share/${finalAttrs.pname}" -type f \( -name "*.sh" -o -name "*.py" \) -exec chmod +x {} +
    cp LICENSE.md UPSTREAM.md README.md CHANGELOG.md "$out/share/${finalAttrs.pname}/"
    install -Dm755 bin/kairo  "$out/bin/.kairo-wrapped"
    install -Dm755 bin/kairod "$out/bin/.kairod-wrapped"
    install -Dm644 src/assets/applications/kairo.desktop "$out/share/applications/kairo.desktop"
    substituteInPlace "$out/share/applications/kairo.desktop" --replace-fail "Exec=kairo " "Exec=$out/bin/kairo "
    install -Dm644 src/assets/kairo-logo.svg "$out/share/icons/hicolor/scalable/apps/kairo.svg"
    runHook postInstall
  '';
  postFixup = ''
    for bin in kairo kairod; do
      makeWrapper "$out/bin/.$bin-wrapped" "$out/bin/$bin" \
        "''${qtWrapperArgs[@]}" \
        --prefix QML2_IMPORT_PATH : "${qmlImportPath}" \
        --prefix QT_PLUGIN_PATH : "${qtPluginPath}" \
        --set KAIRO_DIR "$out/share/${finalAttrs.pname}" \
        --set KAIRO_VERSION "${finalAttrs.version}" \
        --prefix PATH : "${lib.makeBinPath pathDeps}"
    done
  '';
  passthru = { inherit pathDeps qtDeps pythonEnv; };
  meta = with lib; {
    description = "Kairo — a Hyprland desktop shell";
    license = licenses.agpl3Only;
    platforms = platforms.linux;
    mainProgram = "kairo";
  };
})
