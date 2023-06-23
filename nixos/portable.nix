{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.generalized;
in
{
  imports = [
    ./desktop.nix
  ];

  config = {
    console.font = "ter-132b";
    services.logind = {
      lidSwitchExternalPower = "ignore";
      lidSwitch = "suspend";
      extraConfig = ''
        HandlePowerKey=ignore
        HandleSuspendKey=hibernate
      '';
    };

    environment.systemPackages = with pkgs; [
      mdadm
      acpi brightnessctl
      xournalpp
    ];

    specialisation.hardened.configuration = {
      system.nixos.tags = ["hardened"];
      boot.kernelPackages = pkgs.linuxKernel.packages.linux_hardened;
    };

    specialisation.kmscon.configuration = {
      system.nixos.tags = ["kmscon" "hardened"];
      boot.kernelPackages = pkgs.linuxKernel.packages.linux_hardened;

      generalized = {
        wayland = lib.mkForce false;
        xorg = lib.mkForce false;
      };

      services = {
        kmscon = {
          enable = true;
          hwRender = true;
          fonts = [
            {
              name = "IBM Plex Mono";
              package = pkgs.ibm-plex;
            }
          ];
          extraConfig = ''
            font-size=30

            xkb-layout=de
            xkb-variant=bone
            xkb-repeat-rate=30
            xkb-repeat-delay=260

            palette=custom

            palette-black=33, 34, 36
            palette-red=255, 147, 101
            palette-green=17, 211, 150
            palette-yellow=199, 183, 0
            palette-blue=0, 199, 247
            palette-magenta=250, 134, 206
            palette-cyan=170, 169, 255
            palette-light-grey=182, 179, 180
            palette-dark-grey=127, 125, 204
            palette-light-red=255, 147, 101
            palette-light-green=17, 211, 150
            palette-light-yellow=199, 183, 0
            palette-light-blue=0, 199, 247
            palette-light-magenta=250, 134, 206
            palette-light-cyan=170, 169, 255
            palette-white=182, 179, 180
            palette-foreground=182, 179, 180
            palette-background=33, 34, 36
          '';
        };
      };
    };
  };
}
