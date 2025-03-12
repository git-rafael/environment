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

    (pkgs.nerdfonts.override { fonts = [ "FiraCode" "DroidSansMono" ]; })
    (pkgs.buildFHSUserEnv {
      name = "oi";
      setLocale = "en_US.UTF-8";
      targetPkgs = pkgs: (with pkgs; [
        rustup
        stdenv.cc
        pkg-config
        
        zlib
        glib.dev
        dbus.dev
        libnotify
        tesseract
        openssl.dev
        
        python311
        python311Packages.pip
        python311Packages.cmake
        python311Packages.tkinter
      ]);

      runScript = "interpreter";
      profile = ''
        readonly VENV_DIR="$HOME/.open-interpreter/venv";
        if [ ! -d "$VENV_DIR" ]; then
          trap "rm -rf $VENV_DIR" ERR;
          python -m venv "$VENV_DIR";
          source "$VENV_DIR/bin/activate";
          pip install --quiet --no-input --no-cache-dir --upgrade --break-system-packages open-interpreter opencv-python plyer pyautogui pywinctl dbus-python pip;
        else
          source "$VENV_DIR/bin/activate";
        fi
      '';
    })
  ];
  
  home.file = {
    ".config/open-interpreter/profiles/default.yaml".text = builtins.readFile ../resources/settings/oi.yaml;
  };

  fonts.fontconfig = {
    enable = pkgs.lib.mkForce true;
    defaultFonts.emoji = [
      "FiraCode"
    ];
  };
  
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
