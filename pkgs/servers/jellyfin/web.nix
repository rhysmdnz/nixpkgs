{ lib
, fetchFromGitHub
, stdenv
, buildNpmPackage
, nix-update-script
, giflib
, pixman
, cairo
, pango
, pkg-config
}:

buildNpmPackage rec {
  pname = "jellyfin-web";
  version = "10.9";

  src = fetchFromGitHub {
    owner = "jellyfin";
    repo = "jellyfin-web";
    rev = "82292d5715c1a53359879943f0a739399322d43e";
    hash = "sha256-v6inWtm/mfn/VtGUCCLNbsp51tycUpKv0iDc4AjqVfE=";
  };

  npmDepsHash = "sha256-Qhfiq+ILsXrGUufOUHogXl05zCZC2YHWpVim9yIEJVs=";
  makeCacheWritable = true;

  npmBuildScript = [ "build:production" ];

  nativeBuildInputs = [
      pkg-config
  ];

  buildInputs = [
      giflib
      pixman
      cairo
      pango
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share
    cp -a dist $out/share/jellyfin-web

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script {};

  meta = with lib; {
    description = "Web Client for Jellyfin";
    homepage = "https://jellyfin.org/";
    license = licenses.gpl2Plus;
    maintainers = with maintainers; [ nyanloutre minijackson purcell jojosch ];
  };
}
