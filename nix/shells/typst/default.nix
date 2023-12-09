{ pkgs ? import (builtins.fetchTarball {
  name = "nixpkgs-typst-lsp-0-12-0";
  url = "https://github.com/nixos/nixpkgs/archive/66c64fcf35be6ee2e5d9db6c2e215646a8522168.tar.gz";
  sha256 = "sha256:1x9a0fwxshn4y916ndn46gxayjxpbf3qh5y1wd5y80s4yi7nyh07";
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
