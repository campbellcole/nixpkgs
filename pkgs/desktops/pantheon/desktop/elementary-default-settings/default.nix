{ lib
, stdenv
, fetchFromGitHub
, fetchpatch
, nix-update-script
, meson
, ninja
, nixos-artwork
, glib
, pkg-config
, dbus
, polkit
, accountsservice
, python3
}:

stdenv.mkDerivation rec {
  pname = "elementary-default-settings";
  version = "7.0.2";

  src = fetchFromGitHub {
    owner = "elementary";
    repo = "default-settings";
    rev = version;
    sha256 = "sha256-YFI1UM7CxjYkoIhSg9Fn81Ze6DX7D7p89xibk7ik8bI=";
  };

  patches = [
    # Don't set picture-uri-dark. elementary-gsettings-schemas won't
    # aware of our custom remove-backgrounds.gschema.override so it
    # will be a confusing invalid value otherwise (though gala actually
    # can handle it well).
    # https://github.com/elementary/default-settings/pull/282
    (fetchpatch {
      url = "https://github.com/elementary/default-settings/commit/881f84b8316e549ab627b7ac9acf352e0346a1a4.patch";
      sha256 = "sha256-zf2Anr+ljLjHbn5ZmRj3nCRVJ52rwe4EkwdIfSOGeLQ=";
    })
    # https://github.com/elementary/default-settings/pull/283
    (fetchpatch {
      url = "https://github.com/elementary/default-settings/commit/37ef6062a8651875dd9d927c5730155c8b26e953.patch";
      sha256 = "sha256-u7rrwuHgMPn1eIyIuwJcBgy8SshaXgrgFTSNm8IHbaY=";
    })
  ];

  nativeBuildInputs = [
    accountsservice
    dbus
    glib # polkit requires
    meson
    ninja
    pkg-config
    polkit
    python3
  ];

  mesonFlags = [
    "--sysconfdir=${placeholder "out"}/etc"
    "-Ddefault-wallpaper=${nixos-artwork.wallpapers.simple-dark-gray.gnomeFilePath}"
    "-Dplank-dockitems=false"
  ];

  postPatch = ''
    chmod +x meson/post_install.py
    patchShebangs meson/post_install.py
  '';

  preInstall = ''
    # Install our override for plank dockitems as the desktop file path is different.
    schema_dir=$out/share/glib-2.0/schemas
    install -D ${./overrides/plank-dockitems.gschema.override} $schema_dir/plank-dockitems.gschema.override

    # Our launchers that use paths at /run/current-system/sw/bin
    mkdir -p $out/etc/skel/.config/plank/dock1
    cp -avr ${./launchers} $out/etc/skel/.config/plank/dock1/launchers
  '';

  postFixup = ''
    # https://github.com/elementary/default-settings/issues/55
    rm -r $out/share/cups
    rm -r $out/share/applications
  '';

  passthru = {
    updateScript = nix-update-script { };
  };

  meta = with lib; {
    description = "Default settings and configuration files for elementary";
    homepage = "https://github.com/elementary/default-settings";
    license = licenses.gpl2Plus;
    platforms = platforms.linux;
    maintainers = teams.pantheon.members;
  };
}
