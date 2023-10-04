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
  version = "0.1.2";

  src = fetchFromGitHub {
    owner = "MultisampledNight";
    repo = pname;
    rev = version;
    sha256 = "sha256-FSdADmCzi5K2nL4xoeR4BhZceLSToXcaU9Xqp2pu/Cg=";
  };

  cargoSha256 = "sha256-GKI+/n+8+HZmKzVgD57gFPVzZjUItc4I+D6hEkCHc9Y=";

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
