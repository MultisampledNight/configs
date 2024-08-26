{ pkgs ? import (builtins.fetchTarball {
  name = "nixpkgs-2024-03-17";
  url = "https://github.com/nixos/nixpkgs/archive/f7bfbe8bb1655678ca97bc90e11ee662a2ac262f.tar.gz";
  sha256 = "1wxdxzs2af6xi4i22cn3pss1lxpvg2vbc79sz75y9290qz2xv097";
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
