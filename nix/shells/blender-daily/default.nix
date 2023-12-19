with import <nixpkgs> {};

mkShell {
  NIX_LD_LIBRARY_PATH = lib.makeLibraryPath ([
    stdenv.cc.cc
    libz
    libGL
    wayland
    fontconfig
  ] ++ (with xorg; [
    libXext libICE libX11 libSM libXi libxkbcommon libXfixes libXrender libXxf86vm libX11
    libXcursor libXinerama libXrandr
  ]));
  NIX_LD = lib.fileContents "${stdenv.cc}/nix-support/dynamic-linker";
}
