{ pkgs, edgePkgs, features, self, ... }:

let
  withUI = builtins.elem "ui" features;
  forWork = builtins.elem "work" features;
  caCertBundle = "/etc/ssl/certs/ca-bundle.crt";

  env-load = pkgs.writeShellScriptBin "env-load" (builtins.readFile ../resources/scripts/env-load);
  env-shell = pkgs.writeShellScriptBin "env-shell" (builtins.readFile ../resources/scripts/env-shell);
  env-agent = pkgs.writeShellScriptBin "env-agent" (builtins.readFile ../resources/scripts/env-agent);

  pi = let
    npm = pkgs.writeShellScriptBin "npm" ''
      export npm_config_prefix="$HOME/.pi/agent/npm"
      export NPM_CONFIG_PREFIX="$HOME/.pi/agent/npm"
      export PATH="$HOME/.pi/agent/npm/bin''${PATH:+:$PATH}"
      exec ${pkgs.nodejs}/bin/npm "$@"
    '';
    piPath = pkgs.lib.makeBinPath ([ npm ] ++ pkgs.lib.optionals withUI [ pkgs.google-chrome ]);
  in pkgs.symlinkJoin {
    name = "pi-coding-agent";
    paths = [ edgePkgs.pi-coding-agent ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/pi \
        --run 'export PATH="$HOME/.pi/agent/npm/bin:${piPath}''${PATH:+:''$PATH}"'
    '';
  };

  python = pkgs.python3.withPackages (ps: with ps; [
    boto3
    openai
    google-generativeai
  ]);
in {
  home.sessionVariables = pkgs.lib.optionalAttrs forWork {
    NODE_EXTRA_CA_CERTS = caCertBundle;
    SSL_CERT_FILE = caCertBundle;
    REQUESTS_CA_BUNDLE = caCertBundle;
  };

  home.packages = with pkgs; [
    env-load
    env-shell
    env-agent
    pi

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

    # Agent instructions — Codex convention (~/.codex/AGENTS.md)
    ".codex/AGENTS.md" = {
      force = true;
      source = ../resources/settings/AGENTS.md;
    };

    # Agent instructions — Claude Code convention (~/.claude/CLAUDE.md)
    ".claude/CLAUDE.md" = {
      force = true;
      source = ../resources/settings/AGENTS.md;
    };

    # Agent instructions — Goose convention (~/.config/goose/AGENTS.md)
    ".config/goose/AGENTS.md" = {
      force = true;
      source = ../resources/settings/AGENTS.md;
    };

    # Agent Skills — cross-client convention (~/.agents/skills/)
    ".agents/skills" = {
      source = "${self}/resources/agents/skills";
    };

    # Agent Skills — Codex user convention (~/.codex/skills/user/)
    ".codex/skills/user" = {
      source = "${self}/resources/agents/skills";
    };

    # Agent Skills — XDG cross-client convention, used by Goose and Amp (~/.config/agents/skills/)
    ".config/agents/skills" = {
      source = "${self}/resources/agents/skills";
    };

    # Agent Skills — Claude Code convention (~/.claude/skills/)
    ".claude/skills" = {
      source = "${self}/resources/agents/skills";
    };

    # Agent Skills — Gemini CLI convention (~/.gemini/skills/)
    ".gemini/skills" = {
      source = "${self}/resources/agents/skills";
    };

    # Pi global settings
    ".pi/agent/settings.json" = {
      force = true;
      source = ../resources/agents/pi/settings.json;
    };

    # Pi keybindings
    ".pi/agent/keybindings.json" = {
      force = true;
      source = ../resources/agents/pi/keybindings.json;
    };

    # Pi session summary config
    ".pi/agent/session-summary.json" = {
      force = true;
      source = ../resources/agents/pi/session-summary.json;
    };

    # Pi extensions
    ".pi/agent/extensions/herdr-workspace-summary.ts" = {
      force = true;
      source = ../resources/agents/pi/extensions/herdr-workspace-summary.ts;
    };

    ".pi/agent/extensions/herdr-spawn.ts" = {
      force = true;
      source = ../resources/agents/pi/extensions/herdr-spawn.ts;
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

    settings = {
      user.name = "Rafael Oliveira";

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

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };
  
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;    
  };
  
  programs.broot = {
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
      herdr = "env-agent";
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
    mouse = true;

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
