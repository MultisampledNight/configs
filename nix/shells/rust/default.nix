{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell rec {
  buildInputs = with pkgs; [
    cargo rustc rustfmt clippy rust-analyzer rustup

    gdb
    clang llvmPackages_latest.lld llvmPackages.libclang
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
