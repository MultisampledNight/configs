#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p python3
# vim: ft=python
import argparse
import os
import shutil
import subprocess
import sys
from itertools import starmap
from pathlib import Path

ROOT = "/"
USER = "multisn8"


def destinations():
    raise Exception("not implemented yet")
    # Named the same under ~/.config as well as $repo/config
    literal = [
        "alacritty",
        "cargo/config.toml",
        "evcxr",
        "godot",
        "helix",
        "i3",
        "layaway",
        "nvim",
        "sway",
        "swaylock",
        "waybar",
        "zathura",
    ]

    # Other mappings between ~/.config and $repo/config
    config = {
        "gtk-3.0": "gtk",
        "gtk-4.0": "gtk",
        "pipewire/pipewire.conf.d": "pipewire",
    }

    # "Special" things in ~/zukunftslosigkeit so elusive can find them
    zukunftslosigkeit = {
        "scripts": "scripts",
        "shells": "nix/shells",
    }

    # Anything else that belongs in ~
    home = {
        ".gitignore-global": "git/gitignore-global",
        ".gitignore": "git/gitconfig",
        ".rgignore": "ripgrep/rgignore",
        ".zshrc": "zsh/zshrc",
        ".zlogin": "zsh/zlogin",
        ".background-image": "../wallpapers/wallpaper",
    }

    # Anything else
    root = {
        "/etc/nixos": "nixos",
    }

    all = ""

    return all


def distribute_symlinks(
    destinations=destinations(),
    user=USER,
    root=ROOT,
    exclude_nixos=False,
    no_backup=False,
    actually_install=False,
):
    repo_root = Path(__file__).resolve().parent

    for name, target in destinations.items():
        install_one(name, target)


def install_one(name, target):
    # TODO: some day I'll need to rename exclude_nixos and have it check for a non-user path instead
    if exclude_nixos and "nixos" in target:
        return
    name = expanduser(name, root=root, user=user)
    target = (repo_root / target).resolve()

    remove(name)

    try:
        name.parent.mkdir(parents=True, exist_ok=True)
        if actually_install:
            # directly copy to the destination instead
            if link_target.is_file():
                shutil.copy2(link_target, link_name)
            else:
                shutil.copytree(link_target, link_name)
        else:
            # create the symlink
            link_name.symlink_to(link_target)
    except PermissionError:
        print(
            f"Skipping {link_name} due to missing perms",
            file=sys.stderr,
        )


def dictmap(op, subject):
    """
    Applies `op`, a callable accepting the key and value as parameters,
    to the dictionary `subject`.
    """
    return dict(starmap(op, subject.items()))


def expanduser(path, root=ROOT, user=USER):
    return Path(root) / str(path).replace("~", f"home/{user}")


def ensure_root(msg="Must be run as root.", fail_fast=True):
    if os.geteuid() != 0:
        print(
            msg,
            file=sys.stderr,
        )
        if fail_fast:
            sys.exit(1)


def parse_args():
    parser = argparse.ArgumentParser(
        description="Puts symlinks where specified. Does not take any precautions against path traversal attacks."
    )
    parser.add_argument("--root", action="store", default=ROOT)
    parser.add_argument("--user", action="store", default=USER)
    parser.add_argument("--exclude-nixos", action="store_true")
    parser.add_argument("--actually-install", action="store_true")
    return parser.parse_args()


def remove(path: Path):
    if not path.exists():
        # can't delete something that doesn't exist
        return

    if path.is_file() or path.is_symlink():
        path.unlink()
    else:
        shutil.rmtree(path)


def main():
    args = parse_args()
    if not args.exclude_nixos:
        ensure_root(
            "Should be run as root, since it also symlinks /etc/nixos. "
            "Prepare for some errors (or run with --exclude-nixos)",
            fail_fast=False,
        )
    distribute_symlinks(
        user=args.user,
        root=args.root,
        exclude_nixos=args.exclude_nixos,
        no_backup=args.no_backup,
        actually_install=args.actually_install,
    )


if __name__ == "__main__":
    main()
