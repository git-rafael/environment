{ pkgs, edgePkgs, features, self, ... }:

let
  withUI = builtins.elem "ui" features;

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

  claude-code = pkgs.symlinkJoin {
    name = "claude-code";
    paths = [ edgePkgs.claude-code ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/claude \
        --set CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC 1
    '';
  };

  agent-browser = pkgs.stdenv.mkDerivation {
    pname = "agent-browser";
    version = "0.20.13";
    src = pkgs.fetchurl {
      url = "https://github.com/vercel-labs/agent-browser/releases/download/v0.20.13/agent-browser-linux-x64";
      hash = "sha256-NcS6RcK0X8faGfPxDTMNMo53Vc/HyHO2IBoIOtbQrZk=";
    };
    nativeBuildInputs = [ pkgs.autoPatchelfHook pkgs.makeWrapper ];
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/agent-browser
      chmod +x $out/bin/agent-browser
    '' + pkgs.lib.optionalString withUI ''
      wrapProgram $out/bin/agent-browser \
        --set AGENT_BROWSER_EXECUTABLE_PATH "${pkgs.google-chrome}/bin/google-chrome-stable"
    '';
  };

  herdrAsset = {
    x86_64-linux = {
      url = "https://github.com/ogulcancelik/herdr/releases/download/v0.5.0/herdr-linux-x86_64";
      sha256 = "04hayacgnj3wkkq4sxlbs9fi2xcg8lbi1xk8afavrp3fjbv66bd3";
    };
    aarch64-linux = {
      url = "https://github.com/ogulcancelik/herdr/releases/download/v0.5.0/herdr-linux-aarch64";
      sha256 = "17ab1hgfa9vfd4wxhgm4g9lq1yf0wv8giwbl9rqp715c3kbnln4j";
    };
  }.${pkgs.stdenv.hostPlatform.system} or null;

  herdr = if herdrAsset != null then pkgs.stdenvNoCC.mkDerivation {
    pname = "herdr";
    version = "0.5.0";
    src = pkgs.fetchurl herdrAsset;
    dontUnpack = true;
    installPhase = ''
      install -Dm755 "$src" "$out/bin/herdr"
    '';
    meta = with pkgs.lib; {
      description = "Terminal workspace manager for AI coding agents";
      homepage = "https://herdr.dev";
      license = licenses.agpl3Plus;
      mainProgram = "herdr";
      platforms = [ "x86_64-linux" "aarch64-linux" ];
    };
  } else null;
in {
  home.packages = [
    env-agent
    pi
    claude-code
    agent-browser
    edgePkgs.codex
    edgePkgs.ollama
  ] ++ pkgs.lib.optionals (herdrAsset != null) [
    herdr
  ];

  home.file = {
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

    # Agent Skills — cross-client convention (~/.agents/skills/)
    ".agents/skills" = {
      source = "${self}/resources/agents/skills";
    };

    # Agent Skills — Codex user convention (~/.codex/skills/user/)
    ".codex/skills/user" = {
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

    # Pi extensions
    ".pi/agent/extensions/herdr-utils" = {
      force = true;
      source = ../resources/agents/pi/extensions/herdr-utils;
    };

    ".pi/agent/extensions/shell.ts" = {
      force = true;
      source = ../resources/agents/pi/extensions/shell.ts;
    };
  };
}
