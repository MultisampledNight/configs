{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell rec {
  buildInputs = with pkgs; [
    cargo rustc rust-analyzer rustup

    clang llvmPackages_latest.lld llvmPackages.libclang
    openssl pkg-config
    wasm-pack evcxr tokei
    libGL directx-shader-compiler
    libxkbcommon
    wayland xorg.libX11 xorg.libXcursor xorg.libXrandr xorg.libXi
    fontconfig freetype

    mdbook mdbook-linkcheck mdbook-pagetoc

    python3 valgrind lldb rr
    renderdoc
  ];
  RUSTC_VERSION = pkgs.lib.strings.removeSuffix "\n" (
    pkgs.lib.readFile ./rust-toolchain
  );
  LIBCLANG_PATH = pkgs.lib.makeLibraryPath [pkgs.llvmPackages.libclang.lib];

  BINDGEN_EXTRA_CLANG_ARGS = with pkgs.llvmPackages_latest.libclang; [
    ''-I"${lib}/lib/clang/${version}"''
  ];

  shellHook = ''
    export PATH=$PATH:''${CARGO_HOME:-~/.cargo}/bin
    export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:${builtins.toString (pkgs.lib.makeLibraryPath buildInputs)}";
  '';
}
