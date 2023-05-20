#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p python3
# vim: ft=python
import os
import shutil
import sys
from pathlib import Path


HOME_DIR = "/home/multisn8"
BACKUP_DIR = "~/_archive/backup"
CONFIG_DESTINATIONS = {
    # user stuff
    "alacritty": "~/.config/alacritty",
    "evcxr": "~/.config/evcxr",
    "mako": "~/.config/mako",
    "nvim": "~/.config/nvim",
    "sway": "~/.config/sway",
    "waybar": "~/.config/waybar",
    "zsh/zshrc": "~/.zshrc",
    # system wide stuff
    "nixos": "/etc/nixos",
}


def distribute_symlinks(destinations=CONFIG_DESTINATIONS, backup_dir=BACKUP_DIR):
    backup_dir = expanduser(backup_dir)
    backup_dir.mkdir(parents=True, exist_ok=True)
    repo_root = Path(__file__).resolve().parent

    for repo_subpath, link_name in destinations.items():
        link_name = expanduser(link_name)
        link_target = (repo_root / repo_subpath).resolve()

        # back up the old content (if any)
        try:
            shutil.move(link_name, backup_dir)
        except FileNotFoundError:
            pass

        # then actually create the link
        link_name.parent.mkdir(parents=True, exist_ok=True)
        link_name.symlink_to(link_target)


def expanduser(path):
    return Path(str(path).replace("~", HOME_DIR))


def ensure_root():
    if os.geteuid() != 0:
        print(
            "Must be run as root, since it also symlinks /etc/nixos",
            file=sys.stderr,
        )
        sys.exit(1)


def main():
    ensure_root()
    distribute_symlinks()


if __name__ == "__main__":
    main()
