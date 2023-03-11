{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell rec {
  buildInputs = with pkgs; [
    clang llvmPackages_latest.lld llvmPackages.libclang
    openssl pkg-config webkitgtk.dev
    rustup wasm-pack rust-analyzer evcxr

    python3 valgrind
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
    export PATH=$PATH:''${RUSTUP_HOME:-~/.rustup}/toolchains/$RUSTC_VERSION-x86_64-unknown-linux-gnu/bin
  '';
}
