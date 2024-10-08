#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p python3
# vim: ft=python
import argparse
import os
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = "/"
USER = "multisn8"
CONFIG_DESTINATIONS = {
    # user stuff
    "config/alacritty": "~/.config/alacritty",
    "config/cargo/config.toml": "~/.cargo/config.toml",
    "config/evcxr": "~/.config/evcxr",
    "config/git/gitignore-global": "~/.gitignore-global",
    "config/git/gitconfig": "~/.gitconfig",
    "config/godot/editor_settings-4.tres": "~/.config/godot/editor_settings-4.tres",
    "config/gtk-3.0": "~/.config/gtk-3.0",
    "config/helix": "~/.config/helix",
    "config/i3": "~/.config/i3",
    "config/layaway": "~/.config/layaway",
    "config/nvim": "~/.config/nvim",
    "config/pipewire": "~/.config/pipewire/pipewire.conf.d",
    "config/ripgrep/rgignore": "~/.rgignore",
    "config/sway": "~/.config/sway",
    "config/swaylock": "~/.config/swaylock",
    "config/waybar": "~/.config/waybar",
    "config/zathura/zathurarc": "~/.config/zathura/zathurarc",
    "config/zsh/zshrc": "~/.zshrc",
    "config/zsh/zlogin": "~/.zlogin",
    "wallpapers/wallpaper": "~/.background-image",
    # putting things out of config so elusive gets them
    "scripts": "~/zukunftslosigkeit/scripts",
    "nix/shells": "~/zukunftslosigkeit/shells",
    # system wide stuff
    "nixos": "/etc/nixos",
}


def distribute_symlinks(
    destinations=CONFIG_DESTINATIONS,
    user=USER,
    root=ROOT,
    exclude_nixos=False,
    no_backup=False,
    actually_install=False,
):
    repo_root = Path(__file__).resolve().parent

    for repo_subpath, link_name in destinations.items():
        # TODO: some day I'll need to rename exclude_nixos and have it check for a non-user path instead
        if exclude_nixos and "nixos" in repo_subpath:
            continue
        link_name = expanduser(link_name, root=root, user=user)
        link_target = (repo_root / repo_subpath).resolve()

        # back up the old content (if any)
        if no_backup:
            remove(link_name)
        else:
            subprocess.run(
                ["python3", repo_root / "scripts" / "archive", link_name],
            )

        try:
            link_name.parent.mkdir(parents=True, exist_ok=True)
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
    parser.add_argument("--no-backup", action="store_true")
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
