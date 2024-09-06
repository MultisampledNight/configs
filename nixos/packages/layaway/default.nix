{ lib
, stdenv
, fetchFromGitHub
, rustPlatform
}:

rustPlatform.buildRustPackage rec {
  pname = "layaway";
  version = "0.1.6";

  src = fetchFromGitHub {
    owner = "MultisampledNight";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-HJcw/OeUVNVMz/wsxJPqUQKpZBJ16JqSv2d4zqsvUds=";
  };

  cargoHash = "sha256-m8aAhIQLVWOPuUWjzbTauZ6sN/xbtgj48Hq6XBpjHcc=";

  meta = with lib; {
    description = "Layout creation for Sway via a relative and human-readable DSL.";
    homepage = "https://github.com/MultisampledNight/layaway";
    maintainers = [maintainers.multisn8];
  };
}
