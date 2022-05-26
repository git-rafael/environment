{ config, lib, pkgs, ... }:
let
  laboratoryPackages = import ../packages/laboratory.nix pkgs;
in {
  home.packages = laboratoryPackages;
}
