{ lib, stdenv
, fetchurl
, fetchpatch
, autoreconfHook
, docbook_xml_dtd_45
, docbook-xsl-nons
, which
, libxml2
, gobject-introspection
, gtk-doc
, intltool
, libxslt
, pkg-config
, xmlto
, appstream-glib
, substituteAll
, bison
, xdg-dbus-proxy
, p11-kit
, bubblewrap
, bzip2
, dbus
, glib
, gpgme
, json-glib
, libarchive
, libcap
, libseccomp
, coreutils
, socat
, gettext
, hicolor-icon-theme
, shared-mime-info
, desktop-file-utils
, gtk3
, fuse
, nixosTests
, libsoup
, xz
, zstd
, ostree
, polkit
, python3
, systemd
, xorg
, valgrind
, glib-networking
, wrapGAppsNoGuiHook
, dconf
, gsettings-desktop-schemas
, librsvg
}:

stdenv.mkDerivation rec {
  pname = "flatpak";
  version = "1.11.3";

  # TODO: split out lib once we figure out what to do with triggerdir
  outputs = [ "out" "dev" "man" "doc" "devdoc" "installedTests" ];

  src = fetchurl {
    url = "https://github.com/flatpak/flatpak/releases/download/${version}/${pname}-${version}.tar.xz";
    sha256 = "1284ead93b42acaec511a1649cd64d0df3da851bab2e65cf004bc90828d16b6c";
  };

  patches = [
    # Hardcode paths used by tests and change test runtime generation to use files from Nix store.
    # https://github.com/flatpak/flatpak/issues/1460
    (substituteAll {
      src = ./fix-test-paths.patch;
      inherit coreutils gettext socat gtk3;
      smi = shared-mime-info;
      dfu = desktop-file-utils;
      hicolorIconTheme = hicolor-icon-theme;
    })

    # Hardcode paths used by Flatpak itself.
    (substituteAll {
      src = ./fix-paths.patch;
      p11kit = "${p11-kit.dev}/bin/p11-kit";
    })

    # Adapt paths exposed to sandbox for NixOS.
    (substituteAll {
      src = ./bubblewrap-paths.patch;
      inherit (builtins) storeDir;
    })

    # Allow gtk-doc to find schemas using XML_CATALOG_FILES environment variable.
    # Patch taken from gtk-doc expression.
    ./respect-xml-catalog-files-var.patch

    # Don’t hardcode flatpak binary path in launchers stored under user’s profile otherwise they will break after Flatpak update.
    # https://github.com/NixOS/nixpkgs/issues/43581
    ./use-flatpak-from-path.patch

    # Nix environment hacks should not leak into the apps.
    # https://github.com/NixOS/nixpkgs/issues/53441
    ./unset-env-vars.patch

    # But we want the GDK_PIXBUF_MODULE_FILE from the wrapper affect the icon validator.
    ./validate-icon-pixbuf.patch
  ];

  nativeBuildInputs = [
    autoreconfHook
    libxml2
    docbook_xml_dtd_45
    docbook-xsl-nons
    which
    gobject-introspection
    gtk-doc
    intltool
    libxslt
    pkg-config
    xmlto
    appstream-glib
    bison
    wrapGAppsNoGuiHook
  ];

  buildInputs = [
    bubblewrap
    bzip2
    dbus
    dconf
    gpgme
    json-glib
    libarchive
    libcap
    libseccomp
    libsoup
    xz
    zstd
    polkit
    python3
    systemd
    xorg.libXau
    fuse
    gsettings-desktop-schemas
    glib-networking
    librsvg # for flatpak-validate-icon
  ];

  # Required by flatpak.pc
  propagatedBuildInputs = [
    glib
    ostree
  ];

  checkInputs = [
    valgrind
  ];

  # TODO: some issues with temporary files
  doCheck = false;

  NIX_LDFLAGS = "-lpthread";

  enableParallelBuilding = true;

  configureFlags = [
    "--with-system-bubblewrap=${bubblewrap}/bin/bwrap"
    "--with-system-dbus-proxy=${xdg-dbus-proxy}/bin/xdg-dbus-proxy"
    "--with-dbus-config-dir=${placeholder "out"}/share/dbus-1/system.d"
    "--localstatedir=/var"
    "--enable-gtk-doc"
    "--enable-installed-tests"
  ];

  makeFlags = [
    "installed_testdir=${placeholder "installedTests"}/libexec/installed-tests/flatpak"
    "installed_test_metadir=${placeholder "installedTests"}/share/installed-tests/flatpak"
  ];

  postPatch = let
    vsc-py = python3.withPackages (pp: [
      pp.pyparsing
    ]);
  in ''
    patchShebangs buildutil
    patchShebangs tests
    PATH=${lib.makeBinPath [vsc-py]}:$PATH patchShebangs --build subprojects/variant-schema-compiler/variant-schema-compiler
  '';

  passthru = {
    tests = {
      installedTests = nixosTests.installed-tests.flatpak;
    };
  };

  meta = with lib; {
    description = "Linux application sandboxing and distribution framework";
    homepage = "https://flatpak.org/";
    license = licenses.lgpl21Plus;
    maintainers = with maintainers; [ jtojnar ];
    platforms = platforms.linux;
  };
}
