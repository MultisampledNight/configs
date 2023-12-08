{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell rec {
  buildInputs = with pkgs; [
    rustup
    cargo-audit cargo-expand cargo-flamegraph cargo-nextest
    typos

    gdb lldb
    clang llvmPackages.libclang
    libgcc.lib
    mold 
    openssl pkg-config cmake
    wasm-pack evcxr tokei
    libxkbcommon
    wayland xorg.libX11 xorg.libXcursor xorg.libXrandr xorg.libXi
    fontconfig freetype

    shaderc directx-shader-compiler
    libGL
    vulkan-headers vulkan-loader
    vulkan-tools vulkan-tools-lunarg
    vulkan-validation-layers
    # TODO: for some reason fails when building the image for elusive due to XDG_DATA_DIRS being unbound in the setup hook
    # vulkan-extension-layer
    monado openxr-loader openxr-loader.dev

    mdbook mdbook-linkcheck mdbook-pagetoc

    python3 valgrind lldb rr
    renderdoc
    gnuplot
  ];
  RUSTC_VERSION = pkgs.lib.strings.removeSuffix "\n" (
    pkgs.lib.readFile ./rust-toolchain
  );
  LIBCLANG_PATH = pkgs.lib.makeLibraryPath [pkgs.llvmPackages.libclang.lib];

  BINDGEN_EXTRA_CLANG_ARGS = with pkgs.llvmPackages_latest.libclang; [
    ''-I"${lib}/lib/clang/${version}"''
  ];

  shellHook = ''
    export SHELL_NAME="''${SHELL_NAME:+$SHELL_NAME/}<rust>"
    export PATH="$PATH:''${CARGO_HOME:-~/.cargo}/bin"
    export PATH="$PATH:''${RUSTUP_HOME:-~/.rustup/toolchains/$RUSTC_VERSION-x86_64-unknown-linux/bin}"
    export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:${builtins.toString (pkgs.lib.makeLibraryPath buildInputs)}";

    rustup default $RUSTC_VERSION
    rustup component add rustfmt clippy rust-src rust-analyzer
  '';
}
