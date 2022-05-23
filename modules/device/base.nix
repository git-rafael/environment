{ config, lib, pkgs, ... }:

let
  packages = with pkgs; [
    glibcLocales
    env-load
    direnv
  ];

  env-load = pkgs.writeShellScriptBin "env-load" (builtins.readFile ../../scripts/env-load);

in {
  home.packages = packages;

  programs.home-manager.enable = true;

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnsupportedSystem = true;
}
