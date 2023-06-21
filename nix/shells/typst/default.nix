{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell rec {
  buildInputs = with pkgs; [
    typst typst-lsp
  ];
}
