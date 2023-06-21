{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell rec {
  buildInputs = (with pkgs; [
    nodejs yarn
    yarn2nix
    deno
    rslint
  ]) ++ (with pkgs.nodePackages; [
    typescript
    typescript-language-server
  ]);
}
