{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell rec {
  buildInputs = with pkgs; [
    nmap hashcash openssl
  ];
}
