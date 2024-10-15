#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p python3
# vim: ft=python

# Terminology:
# - Link name: Where the symlink is stored
# - Link target: What the symlink points to

import argparse
import os
import shutil
import subprocess
import sys
from itertools import starmap
from os.path import abspath
from pathlib import Path

ROOT = "/"
USER = "multisn8"


def destinations():
    # Named the same under ~/.config as well as $repo/config
    literal = [
        "alacritty",
        "cargo/config.toml",
        "evcxr",
        "godot",
        "helix",
        "i3",
        "keepassxc",
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

    # Configs in ~ that are under $repo/config
    home_config = {
        ".gitignore-global": "git/gitignore-global",
        ".gitignore": "git/gitconfig",
        ".rgignore": "ripgrep/rgignore",
        ".zshrc": "zsh/zshrc",
        ".zlogin": "zsh/zlogin",
    }
    # Anything else that belongs in ~ and is under $repo
    home = {
        ".background-image": "wallpapers/wallpaper",
    }

    # Anything else
    root = {
        "/etc/nixos": "nixos",
    }

    # merging them all
    config |= dict(map(lambda name: (name, name), literal))

    home |= kvmap(
        lambda name, target: (
            Path(".config") / name,
            Path("config") / target,
        ),
        config,
    )
    home |= valuemap(lambda target: Path("config") / target, home_config)
    home |= keymap(
        lambda name: Path("zukunftslosigkeit") / name,
        zukunftslosigkeit,
    )

    all = root
    # note: using Path("~") rather than Path.home()
    # so expanduser() later can, well, expand it accordingly
    all |= keymap(lambda name: Path("~") / name, home)

    return all


def distribute_symlinks(**cfg):
    for name, target in destinations().items():
        install_one(name, target, **cfg)


def install_one(
    name,
    target,
    user=USER,
    root=ROOT,
    only_user=False,
    actually_install=False,
    verbose=False,
    dry_run=False,
):
    name = Path(name)
    target = Path(target)
    repo = Path(__file__).resolve().parent

    if only_user and name.is_absolute():
        if verbose:
            print("Skipping", name)
        return
    name = expanduser(name, root=root, user=user)
    target = (repo / target).resolve()

    if verbose:
        print(name, "->", target)

    if dry_run:
        return

    try:
        remove(name)

        name.parent.mkdir(parents=True, exist_ok=True)
        if actually_install:
            copy(target, name)
        else:
            name.symlink_to(target)
    except PermissionError:
        print(
            f"Skipping {link_name} due to missing perms",
            file=sys.stderr,
        )


def remove(path: Path):
    if not (path.exists() or path.is_symlink()):
        # can't delete something that doesn't exist
        return

    if path.is_file() or path.is_symlink():
        path.unlink()
    else:
        shutil.rmtree(path)


def copy(source: Path, to: Path):
    if source.is_file():
        shutil.copy2(source, to)
    else:
        shutil.copytree(source, to)


def kvmap(op, subject):
    """
    Applies `op`, a callable accepting the key and value as parameters,
    to the dictionary `subject`.
    """
    return dict(starmap(op, subject.items()))


def keymap(op, subject):
    return kvmap(lambda k, v: (op(k), v), subject)


def valuemap(op, subject):
    return kvmap(lambda k, v: (k, op(v)), subject)


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
    parser.add_argument(
        "--only-user",
        action="store_true",
        help="Do not copy system files like /etc/nixos.",
    )
    parser.add_argument(
        "--actually-install", action="store_true", help="Copy instead of symlinking."
    )
    parser.add_argument(
        "-v",
        "--verbose",
        action="store_true",
        help="Print every single entry that is processed.",
    )
    parser.add_argument(
        "-n",
        "--dry-run",
        action="store_true",
        help="Do not actually perform any changes.",
    )
    return parser.parse_args()


def main():
    args = parse_args()
    if not args.only_user:
        ensure_root(
            "Should be run as root, since it also symlinks /etc/nixos. "
            "Prepare for some errors (or run with --only-user)",
            fail_fast=False,
        )
    distribute_symlinks(**vars(args))


if __name__ == "__main__":
    main()
