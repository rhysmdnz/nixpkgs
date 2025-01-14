{ lib, stdenv, fetchurl, automake, autoconf, libtool, flex, bison, texinfo, fetchpatch

# Optional Dependencies
, ncurses ? null
}:

stdenv.mkDerivation rec {
  pname = "gpm";
  version = "1.20.7";

  src = fetchurl {
    url = "https://www.nico.schottelius.org/software/gpm/archives/gpm-${version}.tar.bz2";
    sha256 = "13d426a8h403ckpc8zyf7s2p5rql0lqbg2bv0454x0pvgbfbf4gh";
  };

  postPatch = ''
    substituteInPlace src/prog/gpm-root.y --replace __sigemptyset sigemptyset
  '';

  nativeBuildInputs = [ automake autoconf libtool flex bison texinfo ];
  buildInputs = [ ncurses ];

  hardeningDisable = [ "format" ];

  NIX_LDFLAGS = "--allow-multiple-definition";

  patches = [
    # musl compat patches, safe everywhere
    (fetchpatch {
      url = "https://raw.githubusercontent.com/gentoo/musl/5aed405d87dfa92a5cab1596f898e9dea07169b8/sys-libs/gpm/files/gpm-1.20.7-musl-missing-headers.patch";
      sha256 = "1g338m6j1sba84wlqp1r6rpabj5nm6ki577hjalg46czg0lfp20h";
    })
    # Touches same code as glibc fix in postPatch above, but on the non-glibc route
    (fetchpatch {
      url = "https://raw.githubusercontent.com/gentoo/musl/5aed405d87dfa92a5cab1596f898e9dea07169b8/sys-libs/gpm/files/gpm-1.20.7-musl-portable-sigaction.patch";
      sha256 = "0hfdqm9977hd5dpzn05y0a6jbj55w1kp4hd9gyzmg9wslmxni4rg";
    })
    (fetchpatch {
      url = "https://raw.githubusercontent.com/gentoo/musl/5aed405d87dfa92a5cab1596f898e9dea07169b8/sys-libs/gpm/files/gpm-1.20.7-sysmacros.patch";
      sha256 = "0lg4l9phvy2n8gy17qsn6zn0qq52vm8g01pgq5kqpr8sd3fb21c2";
    })
    (fetchpatch {
      # upstream build fix against -fno-common compilers like >=gcc-10
      url = "https://github.com/telmich/gpm/commit/f04f24dd5ca5c1c13608b144ab66e2ccd47f106a.patch";
      sha256 = "1q5hl5m61pci2f0x7r5in99rmqh328v1k0zj2693wdlafk9dabks";
    })
  ];
  preConfigure = ''
    ./autogen.sh
  '';

  configureFlags = [
    "--sysconfdir=/etc"
    "--localstatedir=/var"
    (if ncurses == null then "--without-curses" else "--with-curses")
  ];

  # Provide libgpm.so for compatability
  postInstall = ''
    ln -sv $out/lib/libgpm.so.2 $out/lib/libgpm.so
  '';

  meta = with lib; {
    homepage = "https://www.nico.schottelius.org/software/gpm/";
    description = "A daemon that provides mouse support on the Linux console";
    license = licenses.gpl2;
    platforms = platforms.linux ++ platforms.cygwin;
    maintainers = with maintainers; [ eelco ];
  };
}
