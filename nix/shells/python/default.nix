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

  shellHook = ''
    export SHELL_NAME="''${SHELL_NAME:+$SHELL_NAME/}<python>"
  '';
}
