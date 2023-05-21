#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p python3
import os
from pwd import getpwnam

from distribute_symlinks import (
    BACKUP_DIR,
    USER,
    CONFIG_DESTINATIONS,
    ensure_root,
    expanduser,
)


def readjust_perms(destinations=CONFIG_DESTINATIONS, user=USER):
    for link_name in list(destinations.values()) + [BACKUP_DIR]:
        if link_name.startswith("/"):
            # most likely a system config path in /etc, we don't want to change those
            continue

        _, _, uid, gid, *_ = getpwnam(user)
        try:
            os.chown(expanduser(link_name), uid, gid, follow_symlinks=False)
        except PermissionError:
            print(f"Skipping {link_name} due to missing perms", file=sys.stderr)


def main():
    ensure_root(
        "Should be run as root, since the symlinks are very likely to be owned by root",
        fail_fast=False,
    )
    readjust_perms()


if __name__ == "__main__":
    main()
