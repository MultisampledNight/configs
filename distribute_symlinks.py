#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p python3
# vim: ft=python
import os
import shutil
import sys
from datetime import datetime
from pathlib import Path

USER = "multisn8"
HOME_DIR = f"/home/{USER}"
BACKUP_DIR = "~/_archive/backup"
CONFIG_DESTINATIONS = {
    # user stuff
    "alacritty": "~/.config/alacritty",
    "evcxr": "~/.config/evcxr",
    "git/gitignore-global": "~/.gitignore-global",
    "git/gitconfig": "~/.gitconfig",
    "gtk-3.0": "~/.config/gtk-3.0",
    "mako": "~/.config/mako",
    "nvim": "~/.config/nvim",
    "scripts": "~/zukunftslosigkeit/scripts",
    "sway": "~/.config/sway",
    "swaylock": "~/.config/swaylock",
    "wallpapers/wallpaper": "~/.wallpaper",
    "waybar": "~/.config/waybar",
    "zsh/zshrc": "~/.zshrc",
    # system wide stuff
    "nixos": "/etc/nixos",
}


def distribute_symlinks(destinations=CONFIG_DESTINATIONS, backup_dir=BACKUP_DIR):
    time_tag = datetime.now().isoformat()
    backup_dir = expanduser(backup_dir) / time_tag
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
        except PermissionError:
            print(
                f"Skipping {link_name} due to missing perms",
                file=sys.stderr,
            )
            continue

        # then actually create the link
        try:
            link_name.parent.mkdir(parents=True, exist_ok=True)
            link_name.symlink_to(link_target)
        except PermissionError:
            print(
                f"Skipping {link_name} due to missing perms",
                file=sys.stderr,
            )


def expanduser(path):
    return Path(str(path).replace("~", HOME_DIR))


def ensure_root(msg="Must be run as root.", fail_fast=True):
    if os.geteuid() != 0:
        print(
            msg,
            file=sys.stderr,
        )
        if fail_fast:
            sys.exit(1)


def main():
    ensure_root(
        "Should be run as root, since it also symlinks /etc/nixos. Prepare for some errors.",
        fail_fast=False,
    )
    distribute_symlinks()


if __name__ == "__main__":
    main()
