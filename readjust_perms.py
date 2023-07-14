#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p python3
import argparse
import os
from pathlib import Path
from pwd import getpwnam

from distribute_symlinks import (
    BACKUP_DIR,
    USER,
    ROOT,
    CONFIG_DESTINATIONS,
    ensure_root,
    expanduser,
)


def readjust_perms(destinations=CONFIG_DESTINATIONS, user=USER, root=ROOT):
    for link_name in list(destinations.values()) + [BACKUP_DIR]:
        if link_name.startswith("/"):
            # most likely a system config path in /etc, we don't want to change those
            continue

        _, _, uid, gid, *_ = getpwnam(user)
        try:
            os.chown(
                expanduser(link_name, root=root, user=user),
                uid,
                gid,
                follow_symlinks=False,
            )
        except PermissionError:
            print(f"Skipping {link_name} due to missing perms", file=sys.stderr)


def parse_args():
    parser = argparse.ArgumentParser(
        description="Adjusts the symlinks made by the partner script to match the proper owner. Does not take any precautions against path traversal attacks."
    )
    parser.add_argument("--root", action="store", default=ROOT)
    parser.add_argument("--user", action="store", default=USER)
    return parser.parse_args()


def main():
    ensure_root(
        "Should be run as root, since the symlinks are very likely to be owned by root",
        fail_fast=False,
    )
    args = parse_args()
    readjust_perms(user=args.user, root=args.root)


if __name__ == "__main__":
    main()
