{ pkgs, ... }:

let
  env-load = pkgs.writeShellScriptBin "env-load" (builtins.readFile ../resources/scripts/env-load);
  env-shell = pkgs.writeShellScriptBin "env-shell" (builtins.readFile ../resources/scripts/env-shell);

in {
  home.packages = with pkgs; [
    env-load
    env-shell

    vim
    eza
    git

    direnv
    libsecret
  ];
  
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
  
  programs.starship = {
    enable = true;
    settings = {
      add_newline = true;
      
      container = {
        disabled = true;
      };
    };
  };

  programs.zsh = {
    enable = true;

    enableCompletion = true;
    enableAutosuggestions = true;
    syntaxHighlighting.enable = true;

    initExtra = (builtins.readFile ../resources/scripts/zshrc);
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

    extraConfig = (builtins.readFile ../resources/settings/tmux.conf);
  };
}
