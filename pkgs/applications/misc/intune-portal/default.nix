{ stdenv
, lib
, fetchurl
, dpkg
, libuuid
, xorg
, curlMinimal
, openssl
, libsecret
, webkitgtk
, libsoup
, gtk3
, atk
, pango
, glib
, sqlite
, zlib
, systemd
, msalsdk-dbusclient
, pam
}:
stdenv.mkDerivation rec {
  pname = "intune-portal";
  version = "1.2303.10";

  src = fetchurl {
    url = "https://packages.microsoft.com/ubuntu/22.04/prod/pool/main/i/${pname}/${pname}_${version}_amd64.deb";
    hash = "sha256-Y8f2JEAitxqgcU6GOKaVvSjKKtxg3oxy6xHyJnjTTJo=";
  };

  nativeBuildInputs = [ dpkg ];

  unpackCmd = ''
    mkdir -p root
    dpkg-deb -x $curSrc root
  '';


  buildPhase =
    let
      libPath = {
        intune = lib.makeLibraryPath [
          stdenv.cc.cc.lib
          libuuid
          xorg.libX11
          curlMinimal
          openssl
          libsecret
          webkitgtk
          libsoup
          gtk3
          atk
          glib
          pango
          sqlite
          zlib
          systemd
          msalsdk-dbusclient
        ];
        pam = lib.makeLibraryPath [ pam ];
      };
    in
    ''
      runHook preBuild

      patchelf --set-interpreter $(cat $NIX_CC/nix-support/dynamic-linker) --set-rpath ${libPath.intune} opt/microsoft/intune/bin/intune-portal
      patchelf --set-interpreter $(cat $NIX_CC/nix-support/dynamic-linker) --set-rpath ${libPath.intune} opt/microsoft/intune/bin/intune-agent
      patchelf --set-rpath ${libPath.pam} ./usr/lib/x86_64-linux-gnu/security/pam_intune.so

      runHook postBuild
    '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp -a opt/microsoft/intune/bin/* $out/bin/
    cp -a usr/share $out
    cp -a lib $out
    mkdir -p $out/lib/security
    cp -a ./usr/lib/x86_64-linux-gnu/security/pam_intune.so $out/lib/security/
    cp -a usr/lib/tmpfiles.d $out/lib

    substituteInPlace $out/share/applications/intune-portal.desktop \
      --replace /opt/microsoft/intune/bin/intune-portal $out/bin/intune-portal

    substituteInPlace $out/lib/systemd/user/intune-agent.service \
      --replace \
        ExecStart=/opt/microsoft/intune/bin/intune-agent \
        ExecStart=$out/bin/intune-agent

    runHook postInstall
  '';

  dontPatchELF = true;
  passthru.updateScript = ./update.sh;

  meta = with lib; {
    description = "Microsoft Intune Portal allows you to securely access corporate apps, data, and resources";
    homepage = "https://www.microsoft.com/";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    maintainers = with lib.maintainers; [ rhysmdnz ];
  };
}
