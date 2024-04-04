{ lib
, fetchFromGitHub
, fetchurl
, nixosTests
, stdenv
, dotnetCorePackages
, buildDotnetModule
, ffmpeg
, fontconfig
, freetype
, jellyfin-web
, sqlite
}:

buildDotnetModule rec {
  pname = "jellyfin";
  version = "10.9.0"; # ensure that jellyfin-web has matching version

  src = fetchFromGitHub {
    owner = "jellyfin";
    repo = "jellyfin";
    rev = "2428672599763f47d9ac0fc74d9e777e40f7345b";
    sha256 = "sha256-VQPRzyB3ZjdhsiW+JQcm1eQsJnaaTIAG9LAsSY33bRM=";
  };

  patches = [
    # when building some warnings are reported as error and fail the build.
    # ./disable-warnings.patch
  ];

  propagatedBuildInputs = [
    sqlite
  ];

  projectFile = "Jellyfin.Server/Jellyfin.Server.csproj";
  executables = [ "jellyfin" ];
  nugetDeps = ./nuget-deps.nix;
  runtimeDeps = [
    ffmpeg
    fontconfig
    freetype
  ];
  dotnet-sdk = dotnetCorePackages.sdk_8_0;
  dotnet-runtime = dotnetCorePackages.aspnetcore_8_0;
  dotnetBuildFlags = [ "--no-self-contained" ];

  preInstall = ''
    makeWrapperArgs+=(
      --add-flags "--ffmpeg ${ffmpeg}/bin/ffmpeg"
      --add-flags "--webdir ${jellyfin-web}/share/jellyfin-web"
    )
  '';

  passthru.tests = {
    smoke-test = nixosTests.jellyfin;
  };

  passthru.updateScript = ./update.sh;

  meta = with lib; {
    description = "The Free Software Media System";
    homepage = "https://jellyfin.org/";
    # https://github.com/jellyfin/jellyfin/issues/610#issuecomment-537625510
    license = licenses.gpl2Plus;
    maintainers = with maintainers; [ nyanloutre minijackson purcell jojosch ];
    mainProgram = "jellyfin";
    platforms = dotnet-runtime.meta.platforms;
  };
}
