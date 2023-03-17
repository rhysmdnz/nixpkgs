{ stdenv
, lib
, fetchFromGitHub
, dpkg
, jdk
, makeWrapper
, maven
, which
}:
let
  pname = "jnr-posix";
  version = "3.1.16";

  src = fetchFromGitHub {
    owner = "jnr";
    repo = "jnr-posix";
    rev = "jnr-posix-${version}";
    hash = "sha256-Hf6xExhPeoObUj56dY+b9UQ0+Y8KAYSdg12Y95Nbefk=";
  };

  deps = stdenv.mkDerivation {
    name = "${pname}-${version}-deps";
    inherit src;

    nativeBuildInputs = [ jdk maven ];

    buildPhase = ''
      mvn package -Dmaven.test.skip=true -Dmaven.repo.local=$out/.m2 -Dmaven.wagon.rto=5000
    '';

    # keep only *.{pom,jar,sha1,nbm} and delete all ephemeral files with lastModified timestamps inside
    installPhase = ''
      find $out/.m2 -type f -regex '.+\(\.lastUpdated\|resolver-status\.properties\|_remote\.repositories\)' -delete
      find $out/.m2 -type f -iname '*.pom' -exec sed -i -e 's/\r\+$//' {} \;
    '';

    outputHashMode = "recursive";
    outputHash = "sha256-9PxDQAMPr9gblkv+Zq04vydOE3bAyo8CQy5bLHhiCOk=";

    doCheck = false;
  };
in
stdenv.mkDerivation rec {
  inherit version pname src;

  nativeBuildInputs = [ maven which ];

  postPatch = ''
    sed -i "s/\/usr\/bin\/id/$(which id | sed 's#/#\\/#g')/g" src/main/java/jnr/posix/JavaPOSIX.java
  '';

  buildPhase = ''
    runHook preBuild 

    mvn package --offline -Dmaven.test.skip=true -Dmaven.repo.local=$(cp -dpR ${deps}/.m2 ./ && chmod +w -R .m2 && pwd)/.m2

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -D target/${pname}-${version}.jar $out/share/java/${pname}-${version}.jar

    runHook postInstall
  '';

  meta = with lib; {
    description = "jnr-posix is a lightweight cross-platform POSIX emulation layer for Java, written in Java and is part of the JNR project";
    homepage = "https://github.com/jnr/jnr-posix";
    license = with licenses; [ epl20 gpl2Only lgpl21Only ];
    maintainers = with lib.maintainers; [ rhysmdnz ];
  };
}
