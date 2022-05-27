{ config, lib, pkgs, ... }:

let
  packages = with pkgs; [
    thefuck
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
    git
    perl
    asdf
    htop
    ctop
    iotop
    iftop
    rsync
    xclip
    httpie
    openssh
    findutils

    pritunl-ssh

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

  programs.git = {
    enable = true;

    lfs.enable = true;
    delta.enable = true;

    userName = "Rafael Oliveira";

    extraConfig = {
      pull.rebase = false;
      
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

    zplug = {
      enable = true;

      plugins = [
        { name = "zsh-users/zsh-completions"; }
        { name = "zsh-users/zsh-autosuggestions"; }
        { name = "marlonrichert/zsh-autocomplete"; }
        { name = "zsh-users/zsh-syntax-highlighting"; }

        { name = "zplugin/zsh-exa"; }

        { name = "plugins/wd"; tags = [ from:oh-my-zsh ]; }
        { name = "plugins/asdf"; tags = [ from:oh-my-zsh ]; }
        { name = "plugins/extract"; tags = [ from:oh-my-zsh ]; }
        { name = "plugins/copypath"; tags = [ from:oh-my-zsh ]; }
        { name = "plugins/copyfile"; tags = [ from:oh-my-zsh ]; }
        { name = "plugins/web-search"; tags = [ from:oh-my-zsh ]; }
        { name = "plugins/git-auto-fetch"; tags = [ from:oh-my-zsh ]; }
        { name = "plugins/command-not-found"; tags = [ from:oh-my-zsh ]; }
        { name = "frosit/zsh-plugin-homeassistant-cli"; tags = [ from:oh-my-zsh ]; }

        { name = "romkatv/powerlevel10k"; tags = [ as:theme ]; }
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
