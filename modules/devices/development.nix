{ config, lib, pkgs, ... }:

let
  javaPackages = import ../packages/java.nix pkgs;
  dotnetPackages = import ../packages/dotnet.nix pkgs;
  pythonPackages = import ../packages/python.nix pkgs;
  javascriptPackages = import ../packages/javascript.nix pkgs;

  packages = with pkgs; [
    tldr
    
    docker
    docker-compose

    podman
    podman-compose

    git-crypt
    git-hound

    pritunl-ssh

    goss
    dgoss
  ]
  ++ javaPackages
  ++ dotnetPackages
  ++ pythonPackages
  ++ javascriptPackages;

in {
  home.packages = packages;

  programs.git = {
    userName = "Rafael Oliveira";

    lfs.enable = true;
    delta.enable = true;

    extraConfig = {
      core.pager = "delta";

      interactive.diffFilter = "delta --color-only";

      delta.navigate = true;
      delta.navigate = false;
      delta.side-by-side = true;
      delta.line-numbers = true;

      merge.conflictstyle = "diff3";

      diff.colorMoved = "default";
    };
  };
}
