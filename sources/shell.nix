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
    open-interpreter

    noto-fonts
    noto-fonts-emoji
    noto-fonts-cjk-sans
  ];

  fonts.fontconfig = {
    enable = pkgs.lib.mkForce true;
    defaultFonts.emoji = [
      "Noto Color Emoji"
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

    enableCompletion = true;
    autosuggestion.enable = true;
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
      
      aws = {
        symbol = "  ";
      };
      buf = {
        symbol = " ";
      };
      c = {
        symbol = " ";
      };
      conda = {
        symbol = " ";
      };
      crystal = {
        symbol = " ";
      };
      dart = {
        symbol = " ";
      };
      directory = {
        read_only = " 󰌾";
      };
      docker_context = {
        symbol = " ";
      };
      elixir = {
        symbol = " ";
      };
      elm = {
        symbol = " ";
      };
      fennel = {
        symbol = " ";
      };
      fossil_branch = {
        symbol = " ";
      };
      git_branch = {
        symbol = " ";
      };
      golang = {
        symbol = " ";
      };
      guix_shell = {
        symbol = " ";
      };
      haskell = {
        symbol = " ";
      };
      haxe = {
        symbol = " ";
      };
      hg_branch = {
        symbol = " ";
      };
      hostname = {
        ssh_symbol = " ";
      };
      java = {
        symbol = " ";
      };
      julia = {
        symbol = " ";
      };
      kotlin = {
        symbol = " ";
      };
      lua = {
        symbol = " ";
      };
      memory_usage = {
        symbol = "󰍛 ";
      };
      meson = {
        symbol = "󰔷 ";
      };
      nim = {
        symbol = "󰆥 ";
      };
      nix_shell = {
        symbol = " ";
      };
      nodejs = {
        symbol = " ";
      };
      ocaml = {
        symbol = " ";
      };
      os = {
        symbols = {
          Alpaquita = " ";
          Alpine = " ";
          AlmaLinux = " ";
          Amazon = " ";
          Android = " ";
          Arch = " ";
          Artix = " ";
          CentOS = " ";
          Debian = " ";
          DragonFly = " ";
          Emscripten = " ";
          EndeavourOS = " ";
          Fedora = " ";
          FreeBSD = " ";
          Garuda = "󰛓 ";
          Gentoo = " ";
          HardenedBSD = "󰞌 ";
          Illumos = "󰈸 ";
          Kali = " ";
          Linux = " ";
          Mabox = " ";
          Macos = " ";
          Manjaro = " ";
          Mariner = " ";
          MidnightBSD = " ";
          Mint = " ";
          NetBSD = " ";
          NixOS = " ";
          OpenBSD = "󰈺 ";
          openSUSE = " ";
          OracleLinux = "󰌷 ";
          Pop = " ";
          Raspbian = " ";
          Redhat = " ";
          RedHatEnterprise = " ";
          RockyLinux = " ";
          Redox = "󰀘 ";
          Solus = "󰠳 ";
          SUSE = " ";
          Ubuntu = " ";
          Unknown = " ";
          Void = " ";
          Windows = "󰍲 ";
        };
      };
      package = {
        symbol = "󰏗 ";
      };
      perl = {
        symbol = " ";
      };
      php = {
        symbol = " ";
      };
      pijul_channel = {
        symbol = " ";
      };
      python = {
        symbol = " ";
      };
      rlang = {
        symbol = "󰟔 ";
      };
      ruby = {
        symbol = " ";
      };
      rust = {
        symbol = "󱘗 ";
      };
      scala = {
        symbol = " ";
      };
      swift = {
        symbol = " ";
      };
      zig = {
        symbol = " ";
      };
    };
  };
}
