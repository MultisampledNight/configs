{ pkgs ? import (builtins.fetchTarball {
  name = "nixpkgs-typst-0-10-0";
  url = "https://github.com/nixos/nixpkgs/archive/f7ae8d99bb0dd17e4d8d4cf037fd25865bb14715.tar.gz";
  sha256 = "063qs97l8x2drly2llnxjgvgk79r3scgdhlbyaf46ic1lnni3fhc";
}) {
  overlays = [
    (final: prev: {
      # blatantly taken and modified from https://discourse.nixos.org/t/is-it-possible-to-override-cargosha256-in-buildrustpackage/4393/4
      typst-lsp = final.callPackage <nixpkgs/pkgs/development/tools/language-servers/typst-lsp> {
        rustPlatform = final.rustPlatform // {
          buildRustPackage = args: final.rustPlatform.buildRustPackage (args // rec {
            version = "0.12.0";
            src = final.fetchFromGitHub {
              owner = "nvarner";
              repo = "typst-lsp";
              rev = "v${version}";
              hash = "sha256-7T5BxAq67mHve2FeYCN0L63e+2LE7agG1LgmKy5y1bc=";
            };
            cargoLock = {
              lockFile = ./typst-lsp-cargo.lock;
              outputHashes = {
                "typst-0.10.0" = "sha256-qiskc0G/ZdLRZjTicoKIOztRFem59TM4ki23Rl55y9s=";
                "typst-syntax-0.7.0" = "sha256-yrtOmlFAKOqAmhCP7n0HQCOQpU3DWyms5foCdUb9QTg=";
                "typstfmt_lib-0.2.6" = "sha256-UUVbnxIj7kQVpZvSbbB11i6wAvdTnXVk5cNSNoGBeRM=";
              };
            };
          });
        };
      };
    })
  ];
} }:

pkgs.mkShell rec {
  buildInputs = with pkgs; [
    typst
    typst-lsp
  ];

  shellHook = ''
    export SHELL_NAME="''${SHELL_NAME:+$SHELL_NAME/}<typst>"
  '';
}
