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
  };
}
