{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.generalized;

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

  mountFromHost = pkgs.writeShellScriptBin "mount-from-host" ''
    /run/wrappers/bin/mount \
      -t 9p \
      -o version=9p2000.L,msize=32M,trans=virtio, \
         nosuid,nodev,exec \
      $1 $2
  '';
in {
  imports = 
    [
      ./../generalized.nix
      ./../development.nix
    ];

  generalized = {
    hostName = "elusive";
    ssh = true;
    # note that no display protocol is specified
    graphical = true;
    forMulti = false;
  };

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
        packages = [mountFromHost];
      };
    };
  };

  environment.loginShellInit = "${resizeSerialConsole}/bin/resize";

  security.sudo.extraRules = [{
    users = ["multisn8"];
    commands = [
      {
        command = "${mountFromHost}/bin/mount-from-host *";
        options = ["NOPASSWD"];
      }
    ];
  }];

  services.openssh.settings = mkForce {
    PasswordAuthentication = true;
    KbdInteractiveAuthentication = true;
  };

  system.stateVersion = "23.05";
}
