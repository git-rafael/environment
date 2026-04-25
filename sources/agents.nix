{ pkgs, edgePkgs, features, ... }:

let
  env-agent = pkgs.writeShellScriptBin "env-agent" (builtins.readFile ../resources/scripts/env-agent);

  pi = let
    withUI = builtins.elem "ui" features;
    version = "0.70.2";

    package = pkgs.buildNpmPackage {
      pname = "pi-coding-agent";
      inherit version;

      src = pkgs.fetchurl {
        url = "https://registry.npmjs.org/@mariozechner/pi-coding-agent/-/pi-coding-agent-${version}.tgz";
        hash = "sha256-bv+JqGQb0tIUXkm4B7f874y9VUzxlP/DHRq+DjYGddU=";
      };

      sourceRoot = "package";
      postPatch = ''
        cp ${../resources/packages/pi/package-lock.json} package-lock.json
      '';

      npmDepsHash = "sha256-bG1Hg8sH8kY0IEkL2CWdscrVLMVL6PDfDkTS5RviPDg=";
      dontNpmBuild = true;

      meta = with pkgs.lib; {
        description = "Minimal terminal coding harness";
        homepage = "https://github.com/badlogic/pi-mono";
        license = licenses.mit;
        mainProgram = "pi";
      };
    };

    pythonRuntime = pkgs.python3.withPackages (ps: with ps; [
      pip
      setuptools
      wheel
    ]);
    piBuildPath = pkgs.lib.makeBinPath (with pkgs; [
      stdenv.cc
      gnumake
      pkg-config
      binutils
    ]);
    piPython = pkgs.runCommandLocal "pi-python" { } ''
      mkdir -p "$out/bin"

      cat > "$out/bin/python" <<'EOF'
#!${pkgs.runtimeShell}
export PYTHONUSERBASE="$HOME/.pi/agent/python"
export PIP_CACHE_DIR="$HOME/.pi/agent/python/cache/pip"
export PATH="$PYTHONUSERBASE/bin:${piBuildPath}''${PATH:+:$PATH}"
exec ${pythonRuntime}/bin/python3 "$@"
EOF

      cat > "$out/bin/pip" <<'EOF'
#!${pkgs.runtimeShell}
export PYTHONUSERBASE="$HOME/.pi/agent/python"
export PIP_CACHE_DIR="$HOME/.pi/agent/python/cache/pip"
export PIP_USER=1
export PATH="$PYTHONUSERBASE/bin:${piBuildPath}''${PATH:+:$PATH}"
exec ${pythonRuntime}/bin/python3 -m pip "$@"
EOF

      chmod +x "$out/bin/python" "$out/bin/pip"
      ln -s python "$out/bin/python3"
      ln -s pip "$out/bin/pip3"
    '';
    npm = pkgs.writeShellScriptBin "npm" ''
      export npm_config_prefix="$HOME/.pi/agent/npm"
      export NPM_CONFIG_PREFIX="$HOME/.pi/agent/npm"
      export npm_config_cache="$HOME/.pi/agent/npm/cache"
      export NPM_CONFIG_CACHE="$HOME/.pi/agent/npm/cache"
      export PYTHONUSERBASE="$HOME/.pi/agent/python"
      export PIP_CACHE_DIR="$HOME/.pi/agent/python/cache/pip"
      export PATH="$HOME/.pi/agent/python/bin:${piPython}/bin:${piBuildPath}:$HOME/.pi/agent/npm/bin''${PATH:+:$PATH}"
      exec ${pkgs.nodejs}/bin/npm "$@"
    '';
    npx = pkgs.writeShellScriptBin "npx" ''
      export npm_config_prefix="$HOME/.pi/agent/npm"
      export NPM_CONFIG_PREFIX="$HOME/.pi/agent/npm"
      export npm_config_cache="$HOME/.pi/agent/npm/cache"
      export NPM_CONFIG_CACHE="$HOME/.pi/agent/npm/cache"
      export PYTHONUSERBASE="$HOME/.pi/agent/python"
      export PIP_CACHE_DIR="$HOME/.pi/agent/python/cache/pip"
      export PATH="$HOME/.pi/agent/python/bin:${piPython}/bin:${piBuildPath}:$HOME/.pi/agent/npm/bin''${PATH:+:$PATH}"
      exec ${pkgs.nodejs}/bin/npx "$@"
    '';
    piPath = pkgs.lib.makeBinPath ([
      npm
      npx
      piPython
      pythonRuntime
      pkgs.nodejs
      pkgs.stdenv.cc
      pkgs.gnumake
      pkgs.pkg-config
      pkgs.binutils
    ] ++ pkgs.lib.optionals withUI [ pkgs.google-chrome ]);
  in pkgs.symlinkJoin {
    name = "pi-coding-agent";
    paths = [ package ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/pi \
        --run 'export PYTHONUSERBASE="$HOME/.pi/agent/python"' \
        --run 'export PIP_CACHE_DIR="$HOME/.pi/agent/python/cache/pip"' \
        --run 'export PIP_USER=1' \
        --run 'export PATH="$HOME/.pi/agent/python/bin:$HOME/.pi/agent/npm/bin:${piPath}''${PATH:+:''$PATH}"'
    '';
  };

  herdr =
    let
      asset = {
        x86_64-linux = {
          url = "https://github.com/ogulcancelik/herdr/releases/download/v0.5.0/herdr-linux-x86_64";
          sha256 = "04hayacgnj3wkkq4sxlbs9fi2xcg8lbi1xk8afavrp3fjbv66bd3";
        };
        aarch64-linux = {
          url = "https://github.com/ogulcancelik/herdr/releases/download/v0.5.0/herdr-linux-aarch64";
          sha256 = "17ab1hgfa9vfd4wxhgm4g9lq1yf0wv8giwbl9rqp715c3kbnln4j";
        };
      }.${pkgs.stdenv.hostPlatform.system} or null;
    in
      if asset != null then pkgs.stdenvNoCC.mkDerivation {
        pname = "herdr";
        version = "0.5.0";
        src = pkgs.fetchurl asset;
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
    edgePkgs.claude-code
    edgePkgs.codex
    edgePkgs.gemini-cli
    edgePkgs.opencode
    edgePkgs.ollama
  ] ++ pkgs.lib.optionals (herdr != null) [
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

    # Agent instructions — Pi convention (~/.pi/agent/AGENTS.md)
    ".pi/agent/AGENTS.md" = {
      force = true;
      source = ../resources/settings/AGENTS.md;
    };

    # Agent instructions — Gemini CLI convention (~/.gemini/GEMINI.md)
    ".gemini/GEMINI.md" = {
      force = true;
      source = ../resources/settings/AGENTS.md;
    };

    # Agent instructions — OpenCode convention (~/.config/opencode/AGENTS.md)
    ".config/opencode/AGENTS.md" = {
      force = true;
      source = ../resources/settings/AGENTS.md;
    };

    # Herdr settings
    ".config/herdr/config.toml" = {
      force = true;
      source = ../resources/settings/herdr/config.toml;
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
    ".pi/agent/extensions/deep-research-compat.ts" = {
      force = true;
      source = ../resources/agents/pi/extensions/deep-research-compat.ts;
    };

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
