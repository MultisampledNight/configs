{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.generalized;

  customVimPlugins = cfg.pkgs-unstable.vimPlugins.extend (
    cfg.pkgs-unstable.callPackage ./neovim/custom-plugins.nix {}
  );
  latexWithTikz = (pkgs.texlive.combine {
    inherit (pkgs.texlive) scheme-basic pgf standalone german babel;
  });
  cuda = cfg.pkgs-unstable.cudatoolkit;
  nvidia = config.boot.kernelPackages.nvidia_x11;
in {
  documentation = {
    enable = true;
    man.generateCaches = true;
  };

  environment = {
    systemPackages = with pkgs;
    [
      black delta
      inotify-tools geoipWithDatabase
      sshfs
      cfg.pkgs-unstable.godot_4

      # languages (for Rust it's probably better to directly use a shell.nix instead)
      python3 black
      jdk
      llvmPackages_latest.llvm llvmPackages_latest.bintools llvmPackages_latest.lld
      clang sccache latexWithTikz texlab

      direnv
    ]
    ++ (if cfg.graphical then [
        ghidra sqlitebrowser cfg.pkgs-unstable.neovide
        jetbrains.idea-community
    ] else [])
    ++ (if cfg.videoDriver == "nvidia" then [
      cuda
      nvidia
    ] else []);

    sessionVariables = {
      VK_ICD_FILENAMES =
        # hacky but who cares, it's semi-ensured to be there through hardware.opengl.extraPackages anyway
        if cfg.videoDriver != null
        then [
          "/run/opengl-driver/share/vulkan/icd.d/${cfg.videoDriver}_icd.x86_64.json"
          "/run/opengl-driver-32/share/vulkan/icd.d/${cfg.videoDriver}_icd.i686.json"
        ]
        else [];
      NEOVIDE_FORK = "1";
    }
    // (if cfg.videoDriver == "nvidia" then {
      # both required for blender
      CUDA_PATH = "${cuda}";
      CYCLES_CUDA_EXTRA_CFLAGS = concatStringsSep " " [
        "-I${cuda}/targets/x86_64-linux/include"
        "-I${nvidia}/lib"
      ];
    } else {})
    // (if cfg.wayland then {
      NIXOS_OZONE_WL = "1";
      WLR_NO_HARDWARE_CURSORS = "1";
    } else {});

    extraInit = (if cfg.videoDriver == "nvidia" && cfg.xorg then ''
      export LD_LIBRARY_PATH="${config.hardware.nvidia.package}/lib:$LD_LIBRARY_PATH"
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

  users = {
    users = {
      uedev = {
        isNormalUser = true;
        useDefaultShell = true;
        extraGroups = ["antisuns"];
      };
    };
    groups = {
      antisuns = {};
    };
  };

  fileSystems = let
    as-path = user: "/home/${user}/studio/games/antisuns";
  in {
    ${as-path "uedev"} = {
      device = as-path "multisn8";
      fsType = "none";
      options = ["bind"];
    };
  };

  programs = {
    neovim = {
      defaultEditor = true;
      package = cfg.pkgs-unstable.neovim-unwrapped;
      withNodeJs = true;
      withRuby = false;

      configure = {
        customRC = ''
          silent! source ~/.config/nvim/init.vim
        '';

        packages.plugins = with customVimPlugins; {
          start = [
            multisn8-colorschemes

            nvim-cmp cmp-path cmp-cmdline cmp-nvim-lsp
            cmp-vsnip vim-vsnip
            nvim-lspconfig trouble-nvim plenary-nvim
            telescope-nvim telescope-ui-select-nvim
            nvim-dap nvim-dap-ui
            (nvim-treesitter.withPlugins (parsers: with parsers; [
              arduino c cpp c_sharp elixir gdscript javascript julia haskell
              ocaml objc lua python r rust swift typescript
              glsl hlsl wgsl
              cuda
              bash
              gitignore gitcommit git_rebase git_config gitattributes
              vim nix proto godot_resource
              kdl ini toml yaml json json5
              css html
              sql dot mermaid latex bibtex markdown
              diff query vimdoc
              agda
            ]))
            nvim-treesitter-context
            vim-polyglot vim-signify
          ];
          opt = [];
        };
      };
    };

    git.lfs = {
      enable = true;
    };
  };

  fonts = mkIf cfg.graphical {
    packages = with pkgs; [
      hack-font
      roboto roboto-mono
      ibm-plex
      manrope
      source-code-pro
      (nerdfonts.override { fonts = ["FiraCode" "JetBrainsMono"]; })
      departure-mono

      atkinson-hyperlegible
      montserrat
      noto-fonts
      cantarell-fonts
      inter
      overpass
      ttf_bitstream_vera
      ubuntu_font_family
      source-han-sans
    ];

    fontDir.enable = true;
    # this adds a few commonly expected fonts like liberation...
    enableDefaultPackages = true;

    fontconfig = {
      hinting.style = "slight";

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
