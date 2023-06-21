{ pkgs ? import <nixpkgs> {} }:

let
  python3Ext = pkgs.python3.withPackages (ps: [
    ps.ipython
  ]);
in
pkgs.mkShell {
  buildInputs = with pkgs; [
    python3Ext black
  ];
}
