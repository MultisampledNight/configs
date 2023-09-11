{ pkgs ? import <nixos-unstable> {} }:

pkgs.mkShell rec {
  buildInputs = with pkgs; [
    typst typst-lsp
  ];
}
