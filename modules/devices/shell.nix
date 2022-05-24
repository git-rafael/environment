{ config, lib, pkgs, ... }:

let
  packages = with pkgs; [
    ncurses
    gnugrep
    gnused
    gnutar
    gzip
    gawk
    wget
    zip
    jq
    bat
    vim
    git
    perl
    htop
    iotop
    iftop
    rsync
    httpie
    openssh
    findutils

    bitwarden-cli
    home-assistant-cli

    env-shell
  ];

  env-shell = pkgs.writeShellScriptBin "env-shell" (builtins.readFile ../../resources/scripts/env-shell);

in {
  home.packages = packages;

  home.file.".p10k.zsh".source = ../../resources/files/p10k.zsh;

  programs.broot = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zsh = {
    enable = true;

    zplug = {
      enable = true;

      plugins = [
        { name = "zsh-users/zsh-completions"; }
        { name = "zsh-users/zsh-autosuggestions"; }
        { name = "marlonrichert/zsh-autocomplete"; }
        { name = "zsh-users/zsh-syntax-highlighting"; }

      #  { name = "frosit/zsh-plugin-homeassistant-cli"; }

        { name = "plugins/wd"; tags = [ from:oh-my-zsh ]; }
        { name = "plugins/git-auto-fetch"; tags = [ from:oh-my-zsh ]; }

        { name = "romkatv/powerlevel10k"; tags = [ as:theme ]; }
      # { name = "spaceship-prompt/spaceship-prompt"; tags = [ as:theme ]; }
      ];
    };

    initExtra = (builtins.readFile ../../resources/files/zshrc);
  };

  programs.tmux = {
    enable = true;

    keyMode = "vi";
    shortcut = "a";

    newSession = true;
    terminal = "screen-256color";

    shell = "${pkgs.zsh}/bin/zsh";

    # Force tmux to use /tmp for sockets (WSL2 compat)
    # # secureSocket = false;

    # Stop tmux+escape craziness.
    # # escapeTime = 0;

    # aggressiveResize = true; -- Disabled to be iTerm-friendly
    # # baseIndex = 1;

    plugins = with pkgs; [
      tmuxPlugins.better-mouse-mode
    ];

    extraConfig = (builtins.readFile ../../resources/files/tmux.conf);
  };
}
