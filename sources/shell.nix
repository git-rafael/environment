{ pkgs, ... }:

let
  env-load = pkgs.writeShellScriptBin "env-load" (builtins.readFile ../resources/scripts/env-load);
  env-shell = pkgs.writeShellScriptBin "env-shell" (builtins.readFile ../resources/scripts/env-shell);

  python = pkgs.python3.withPackages (ps: with ps; [
    boto3
    openai
    google-generativeai
  ]);
in {
  home.packages = with pkgs; [
    env-load
    env-shell

    vim
    eza

    python
    libsecret

    nerd-fonts.fira-code
    nerd-fonts.droid-sans-mono
  ];
  
  home.file = {
    ".config/zsh_codex.ini" = {
      force = true;
      text = builtins.readFile ../resources/settings/zsh_codex.ini;
    };
  };

  fonts.fontconfig = {
    enable = pkgs.lib.mkForce true;
    defaultFonts.emoji = [
      "FiraCode"
    ];
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
  
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;    
  };
  
  programs.broot = {
    enable = true;
    enableZshIntegration = true;
  };
  
  programs.thefuck = {
    enable = true;
    enableZshIntegration = true;
  };
  
  programs.zsh = {
    enable = true;

    autosuggestion = {
      enable = true;
      strategy = [
        "history"
        "match_prev_cmd"
        "completion"
      ];
    };    
    enableCompletion = true;
    syntaxHighlighting.enable = true;

    initContent = (builtins.readFile ../resources/scripts/zshrc);
    
    shellAliases = {
      # exa aliases
      ls = "exa"; # just replace ls by exa and allow all other exa arguments
      l = "ls -lbF"; # list, size, type
      ll = "ls -la"; # long, all
      llm = "ll --sort=modified"; # list, long, sort by modification date
      la = "ls -lbhHigUmuSa"; # all list
      lx = "ls -lbhHigUmuSa@"; # all list and extended
      tree = "exa --tree"; # tree view
      lS = "exa -1"; # one column by just names

      # other aliases
      open = "xdg-open";
      slugify = "rename \"s/ /_/g; s/_/-/g; s/[^a-zA-Z0-9.-]//g; y/A-Z/a-z/\"";
    };
    
    zplug = {
      enable = true;
      plugins = [
        { name = "tom-doerr/zsh_codex"; }
        { name = "mfaerevaag/wd"; tags = [ as:command use:wd.sh "hook-load:'wd() { . $ZPLUG_REPOS/mfaerevaag/wd/wd.sh }'" ];  }
      ];
    };
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
  
  programs.starship = {
    enable = true;
    settings = {
      add_newline = true;
      
      container = {
        disabled = true;
      };
    };
  };
}
