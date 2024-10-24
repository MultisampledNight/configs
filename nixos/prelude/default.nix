# Commonly used utilities.
#
# Use this by importing it directly but forwarding your module arguments.
# Effectively, if your module is `a`,
# then you probably want to write something akin to:
#
# ```nix
# { config, pkgs, ... } @ args:
#
# with import ./prelude args;
# a
# ```

{ config, pkgs, lib, ... }:

with lib;
{
  # Shorthand for generalized's configuration, usually done by the end-user.
  cfg = config.generalized;

  # Returns the given `value` if `cond`, otherwise an empty list.
  condList = cond: value:
    if cond
    then value
    else [];

  # Maps both keys and values of an attribute set, but each only individually.
  mapKv = keyOp: valueOp: mapAttrs'
    (key: value: nameValuePair
      (keyOp key)
      (valueOp value)
    );
  mapKey = keyOp: mapKv keyOp (v: v);
  mapValue = valueOp: mapKv (k: k) valueOp;

  nixpkgsFromCommit = { rev, hash, opts ? {} }:
    let
      tree = pkgs.fetchzip {
        name = "nixpkgs-${rev}";
        url = "https://github.com/nixos/nixpkgs/archive/${rev}.tar.gz";
        hash = hash;
      };
    in
      import tree opts;
}
