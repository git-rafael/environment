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

    tmuxai

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

  # Configure SSL/TLS to use custom CA bundle with Warp certificate
  home.sessionVariables = {
    NIX_SSL_CERT_FILE = "$HOME/.local/share/ca-certificates/ca-bundle.crt";
    SSL_CERT_FILE = "$HOME/.local/share/ca-certificates/ca-bundle.crt";
    CURL_CA_BUNDLE = "$HOME/.local/share/ca-certificates/ca-bundle.crt";
    NODE_EXTRA_CA_CERTS = "$HOME/.local/share/ca-certificates/ca-bundle.crt";
  };

  home.activation.installWarpCerts = {
    after = [ "writeBoundary" ];
    before = [ ];
    data = ''
      # Create custom CA bundle combining system certs with Warp certificate
      run mkdir -p $HOME/.local/share/ca-certificates
      cat ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt > $HOME/.local/share/ca-certificates/ca-bundle.crt
      echo "" >> $HOME/.local/share/ca-certificates/ca-bundle.crt
      cat ${../resources/certificates/flash_warp_certificate.crt} >> $HOME/.local/share/ca-certificates/ca-bundle.crt

      # Install Warp certificate in NSS database for Chromium/Firefox
      run mkdir -p $HOME/.pki/nssdb
      if [ ! -f "$HOME/.pki/nssdb/cert9.db" ]; then
        run ${pkgs.nss.tools}/bin/certutil -N -d sql:$HOME/.pki/nssdb --empty-password
      fi
      ${pkgs.nss.tools}/bin/certutil -D -d sql:$HOME/.pki/nssdb -n "Cloudflare WARP CA" 2>/dev/null || true
      run ${pkgs.nss.tools}/bin/certutil -A -d sql:$HOME/.pki/nssdb -n "Cloudflare WARP CA" -t "C,," -i ${../resources/certificates/flash_warp_certificate.crt}
    '';
  };
}
