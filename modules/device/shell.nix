{ config, lib, pkgs, ... }:

let
  packages = with pkgs; [
    glibcLocales
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

  env-shell = pkgs.writeShellScriptBin "env-shell" (builtins.readFile ../../scripts/env-shell);

in {
  home.packages = packages;

  programs.broot = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zsh = {
    enable = true;

    history.extended = true;

    enableCompletion = true;
    enableAutosuggestions = true;
    enableSyntaxHighlighting = true;

    zplug = {
      enable = true;

      plugins = [
        { name = "romkatv/powerlevel10k"; tags = [ as:theme ]; }
      # { name = "spaceship-prompt/spaceship-prompt"; tags = [ as:theme ]; }
      
      #  { name = "frosit/zsh-plugin-homeassistant-cli"; }
        
        { name = "plugins/wd"; tags = [ from:oh-my-zsh ]; }
        { name = "plugins/git-auto-fetch"; tags = [ from:oh-my-zsh ]; }
      ];
    };

    initExtra = ''
      export EDITOR='vim';
      export LC_ALL='en_US.UTF-8';
      export TERM='xterm-256color';

      if [ -e ~/.nix-profile/etc/profile.d/nix.sh ]; then
        . ~/.nix-profile/etc/profile.d/nix.sh;
      fi

      if [ -e ~/.env ]; then
        . ~/.env;
      fi

      # # Start up Starship shell
      # eval "$(starship init zsh)";

      # Autocomplete for various utilities
      #command -v hass-cli &>/dev/null && source <(hass-cli completion zsh);
      command -v helm &>/dev/null && source <(helm completion zsh);
      command -v kubectl &>/dev/null && source <(kubectl completion zsh);
      command -v minikube &>/dev/null && source <(minikube completion zsh);
      command -v gh &>/dev/null && source <(gh completion --shell zsh);
      command -v rustup &>/dev/null && rustup completions zsh > ~/.zfunc/_rustup;
      command -v cue &>/dev/null && source <(cue completion zsh);
      command -v npm &>/dev/null && source <(npm completion zsh);
      command -v humioctl &>/dev/null && source <(humioctl completion zsh);
      command -v fluxctl &>/dev/null && source <(fluxctl completion zsh);

      # direnv hook
      eval "$(direnv hook zsh)";
    '';
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

    extraConfig = ''
      set-option -g mouse on

      bind-key -n C-Down split-window -v -c '#{pane_current_path}'
      bind-key -n C-Right split-window -h -c '#{pane_current_path}'
    '';
  };
}
