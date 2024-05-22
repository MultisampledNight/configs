{ lib
, stdenv
, fetchFromGitHub
, rustPlatform
}:

rustPlatform.buildRustPackage rec {
  pname = "layaway";
  version = "0.1.4";

  src = fetchFromGitHub {
    owner = "MultisampledNight";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-o1adhbz+VwIsJABoj7GEbfWivB4Qdx2pCgrZ82LP2R0=";
  };

  cargoSha256 = "sha256-h5sYUskwCZlQ94gv4P0DbtPkzjctpgWSlwiOD72rn5U=";

  meta = with lib; {
    description = "Layout creation for Sway via a relative and human-readable DSL. ";
    homepage = "https://github.com/MultisampledNight/layaway";
    maintainers = [maintainers.multisn8];
  };
}
