{ config, lib, pkgs, ... }:

let
  env-load = pkgs.writeShellScriptBin "env-load" (builtins.readFile ./resources/scripts/env-load);
  env-shell = pkgs.writeShellScriptBin "env-shell" (builtins.readFile ./resources/scripts/env-shell);

  packages = with pkgs; [
    direnv

    ncurses
    gnugrep
    gnused
    gnutar
    gzip
    gawk
    wget
    zip
    jq
    exa
    bat
    vim
    tiv
    git
    perl
    htop
    ctop
    iotop
    iftop
    rsync
    xclip
    httpie
    openssh
    pciutils
    findutils
    coreutils
    cifs-utils

    pritunl-ssh

    bitwarden-cli
    home-assistant-cli

    env-load
    env-shell
  ];

in {
  home.packages = packages;

  programs.broot = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.git = {
    enable = true;

    lfs.enable = true;
    delta.enable = true;

    userName = "Rafael Oliveira";

    extraConfig = {
      pull.rebase = false;
      push.default = "simple";
      
      delta.light = false;
      delta.navigate = true;
      delta.side-by-side = true;
      delta.line-numbers = true;

      merge.conflictstyle = "diff3";

      diff.colorMoved = "default";
    };
  };

  programs.zsh = {
    enable = true;

    enableCompletion = true;
    enableAutosuggestions = true;
    enableSyntaxHighlighting = true;

    zplug = {
      enable = true;

      plugins = [
        { name = "marlonrichert/zsh-autocomplete"; }
        { name = "vifon/deer"; tags = ["use:deer"]; }
        { name = "romkatv/powerlevel10k"; tags = [ as:theme depth:1 ]; }
      ];
    };

    initExtra = (builtins.readFile ./resources/files/zshrc);
  };

  programs.tmux = {
    enable = true;

    keyMode = "vi";
    shortcut = "a";

    newSession = true;
    terminal = "screen-256color";

    shell = "${pkgs.zsh}/bin/zsh";

    plugins = with pkgs; [
      tmuxPlugins.better-mouse-mode
    ];

    extraConfig = (builtins.readFile ./resources/files/tmux.conf);
  };
}
