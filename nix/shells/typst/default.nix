{ pkgs ? import (builtins.fetchTarball {
  name = "nixpkgs-typst-0-10-0";
  url = "https://github.com/nixos/nixpkgs/archive/f7ae8d99bb0dd17e4d8d4cf037fd25865bb14715.tar.gz";
  sha256 = "063qs97l8x2drly2llnxjgvgk79r3scgdhlbyaf46ic1lnni3fhc";
}) {} }:

pkgs.mkShell rec {
  buildInputs = with pkgs; [
    typst
    typst-lsp
  ];

  shellHook = ''
    export SHELL_NAME="''${SHELL_NAME:+$SHELL_NAME/}<typst>"
  '';
}
