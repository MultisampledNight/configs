{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.generalized;
  neovideSmooth = pkgs.callPackage ./neovide/default.nix {};
in {
  documentation = {
    enable = true;
    man.generateCaches = true;
  };

  environment = {
    systemPackages = with pkgs;
    [
      python3 black godot_4 delta
      inotify-tools geoipWithDatabase
      sshfs

      # languages (for Rust it's probably better to directly use a shell.nix instead)
      python3 black
      llvmPackages_latest.llvm llvmPackages_latest.bintools llvmPackages_latest.lld
      clang sccache # texlive.combined.scheme-full texlab
                    # out for now since they add +3min for nothing while testing

      direnv
    ]
    ++ (if cfg.graphical then [
      ghidra sqlitebrowser neovideSmooth
    ] else [])
    ++ (if cfg.forTheGeneralPublic then [
      jetbrains.pycharm-community
      R nodejs openjdk
    ] else [])
    ++ (if cfg.videoDriver == "nvidia" then [
      cudatoolkit
    ] else []);

    sessionVariables = {
      VK_ICD_FILENAMES =
        if cfg.videoDriver == "intel"
        # hacky but who cares, it's semi-ensured to be there through hardware.opengl.extraPackages anyway
        then "/run/opengl-driver/share/vulkan/icd.d/intel_icd.x86_64.json"
        else "";
    }
    // (if cfg.videoDriver == "nvidia" then {
      # both required for blender
      CUDA_PATH = "${pkgs.cudatoolkit}";
      CYCLES_CUDA_EXTRA_CFLAGS = "-I${pkgs.cudatoolkit}/targets/x86_64-linux/include";
    } else {})
    // (if cfg.wayland then {
      NIXOS_OZONE_WL = "1";
      WLR_NO_HARDWARE_CURSORS = "1";
    } else {});

    extraInit = (if cfg.videoDriver == "nvidia" && cfg.xorg then ''
      export LD_LIBRARY_PATH="${pkgs.linuxPackages.nvidia_x11}/lib"
    '' else "")
    + (if cfg.xorg then ''
      # is X even running yet?
      if [[ -n $DISPLAY ]]; then
        # key repeat delay + rate
        xset r rate 260 60
        # turn off the bell sound
        xset b off
      fi
    '' else "");
  };

  programs = {
    neovim = {
      defaultEditor = !cfg.forTheGeneralPublic;
      withNodeJs = true;

      configure = {
        customRC = ''
          silent! source ${pkgs.vimPlugins.vim-plug}/plug.vim
          silent! source ~/.config/nvim/init.vim
        '';
      };
    };

    git.lfs = {
      enable = true;
    };
  };

  fonts = mkIf cfg.graphical {
    fonts = with pkgs; [
      hack-font
      roboto roboto-mono
      ibm-plex
      manrope
      source-code-pro

      cantarell-fonts
      inter
      overpass
      ttf_bitstream_vera
      ubuntu_font_family
    ];

    fontDir.enable = true;
    # this adds a few commonly expected fonts like liberation...
    enableDefaultFonts = true;

    fontconfig = {
      hinting.style = "hintslight";

      # ...while this one sets the actually in-place default fonts
      defaultFonts = {
        serif = ["IBM Plex Serif"];
        sansSerif = ["IBM Plex Sans"];
        monospace = ["IBM Plex Mono"];
      };
    };
  };

  i18n.inputMethod = mkIf cfg.graphical {
    enabled = "ibus";
    ibus.engines = with pkgs.ibus-engines; [hangul];
  };
}
