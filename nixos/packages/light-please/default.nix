{ lib
, stdenv
, fetchFromGitHub
, rustPlatform
, libxkbcommon
, enableWayland ? stdenv.isLinux
, wayland
}:

rustPlatform.buildRustPackage rec {
  pname = "light-please";
  version = "0.2.1";

  src = fetchFromGitHub {
    owner = "MultisampledNight";
    repo = pname;
    rev = version;
    sha256 = "sha256-e41SD7XTbt+Io2opHMoYmAMW5WuqD9Gs1C+kXBOHZpg=";
  };

  cargoSha256 = "sha256-xS2kZnZcTceeSs5kmTDUJugVH/hQf/Kb33C6uZLvavI=";

  postFixup = let
    libPath = lib.makeLibraryPath [
      wayland
      libxkbcommon
    ];
  in ''
    patchelf $out/bin/light-please \
      --add-rpath "${libPath}"
  '';

  meta = with lib; {
    description = "Lightens up the environment before your screen. As in, drawing a white window.";
    homepage = "https://github.com/MultisampledNight/light-please";
    maintainers = [maintainers.multisn8];
  };
}
