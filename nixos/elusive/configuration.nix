{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.generalized;

  configs = ./../..;
  resizeSerialConsole = pkgs.writeShellScriptBin "resize" ''
    if [ -e /dev/tty ]; then
      old=$(stty -g)
      stty raw -echo min 0 time 5
      printf '\033[18t' > /dev/tty
      IFS=';t' read -r _ rows cols _ < /dev/tty
      stty "$old"
      stty cols "$cols" rows "$rows"
    fi
  ''; # https://unix.stackexchange.com/questions/16578/resizable-serial-console-window
in {
  imports = 
    [
      ./../generalized.nix
      ./../development.nix
    ];

  generalized = {
    hostName = "elusive";
    ssh = true;
    wayland = true;
    forMulti = false;
  };

  console.font = "ter-132b";
  boot.loader = {
    systemd-boot.enable = mkForce false;
    grub.enable = mkForce true;
  };

  users = {
    defaultUserShell = pkgs.zsh;
    mutableUsers = false;

    # this is an externally managed VM, no I don't want to have it magically modify itself
    # so make sure the root user is NOT loginable
    allowNoPasswordLogin = true;
    users = {
      root = {
        password = null;
        hashedPassword = null;
        passwordFile = null;
      };

      multisn8 = {
        isNormalUser = true;
        password = "";
        # generate a new one using
        # ssh-keygen -f ~/.ssh/id_to_elusive -t ed25519
        openssh.authorizedKeys.keyFiles = [
          ~/.ssh/id_to_elusive.pub
        ];
      };
    };
  };

  environment.loginShellInit = "${resizeSerialConsole}/bin/resize";

  system.stateVersion = "23.05";
}
