{ pkgs, edgePkgs, features, self, username, ... }:

let
  withUI = builtins.elem "ui" features;

  homeDirectory =
    if username == "null" then "/home"
    else if username == "root" then "/root"
    else "/home/${username}";

  mkOutOfStoreSymlink = path:
    let
      pathStr = toString path;
      name = "hm_${pkgs.lib.replaceStrings [ " " "/" ] [ "-" "-" ] (baseNameOf pathStr)}";
    in
    pkgs.runCommandLocal name { } "ln -s ${pkgs.lib.escapeShellArg pathStr} $out";

  piSkillExports = {
    agent-browser = "git/github.com/vercel-labs/agent-browser/skills/agent-browser";
    skill-creator = "git/github.com/anthropics/skills/skills/skill-creator";
    visual-explainer = "git/github.com/nicobailon/visual-explainer/plugins/visual-explainer";
  };

  localSkillEntries =
    builtins.removeAttrs (builtins.readDir ../resources/agents/skills) (builtins.attrNames piSkillExports);

  sharedAgentSkillsPath = "${homeDirectory}/.agents/skills";
  mkPiManagedSkillPath = relativePath: "${homeDirectory}/.pi/agent/${relativePath}";

  sharedAgentSkills = pkgs.runCommandLocal "shared-agent-skills" { } ''
    mkdir -p "$out"

    ${pkgs.lib.concatMapStringsSep "\n" (name: ''
      ln -s ${pkgs.lib.escapeShellArg "${self}/resources/agents/skills/${name}"} "$out/${name}"
    '') (builtins.attrNames localSkillEntries)}

    ${pkgs.lib.concatStringsSep "\n" (
      pkgs.lib.mapAttrsToList (name: relativePath: ''
        ln -s ${pkgs.lib.escapeShellArg (mkPiManagedSkillPath relativePath)} "$out/${name}"
      '') piSkillExports
    )}
  '';

  env-agent = pkgs.writeShellScriptBin "env-agent" (builtins.readFile ../resources/scripts/env-agent);

  piVersion = "0.70.2";

  piPackage = pkgs.buildNpmPackage {
    pname = "pi-coding-agent";
    version = piVersion;

    src = pkgs.fetchurl {
      url = "https://registry.npmjs.org/@mariozechner/pi-coding-agent/-/pi-coding-agent-${piVersion}.tgz";
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

  pi = let
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
      pkgs.stdenv.cc
      pkgs.gnumake
      pkgs.pkg-config
      pkgs.binutils
    ] ++ pkgs.lib.optionals withUI [ pkgs.google-chrome ]);
  in pkgs.symlinkJoin {
    name = "pi-coding-agent";
    paths = [ piPackage ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/pi \
        --run 'export PYTHONUSERBASE="$HOME/.pi/agent/python"' \
        --run 'export PIP_CACHE_DIR="$HOME/.pi/agent/python/cache/pip"' \
        --run 'export PIP_USER=1' \
        --run 'export PATH="$HOME/.pi/agent/python/bin:$HOME/.pi/agent/npm/bin:${piPath}''${PATH:+:''$PATH}"'
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
    claude-code
    edgePkgs.codex
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

    # Agent Skills — cross-client convention (~/.agents/skills/)
    ".agents/skills" = {
      force = true;
      source = sharedAgentSkills;
    };

    # Agent Skills — Codex user convention (~/.codex/skills/user/)
    ".codex/skills/user" = {
      source = mkOutOfStoreSymlink sharedAgentSkillsPath;
    };

    # Agent Skills — Claude Code convention (~/.claude/skills/)
    ".claude/skills" = {
      source = mkOutOfStoreSymlink sharedAgentSkillsPath;
    };

    # Agent Skills — Gemini CLI convention (~/.gemini/skills/)
    ".gemini/skills" = {
      source = mkOutOfStoreSymlink sharedAgentSkillsPath;
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
