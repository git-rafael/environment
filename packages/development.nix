{ pkgs, edgePkgs, features }:

let
  withUI = builtins.elem "ui" features;
  toWork = builtins.elem "work" features;

  dind = pkgs.writeShellScriptBin "dind" (builtins.readFile ../resources/scripts/dind);
  using = pkgs.writeShellScriptBin "using" (builtins.readFile ../resources/scripts/using);

  flash-install = with pkgs; writeShellApplication {
    name = "flash-install";
    checkPhase = false;

    runtimeInputs = [ 
      gh
      busybox
    ];

    text = ''
      set -e;
      
      gh auth login --hostname github.com;
      readonly CTL_VERSION="$(gh release list --repo flash-tecnologia/flashstage.executable.flashctl | grep Latest | cut -f1 -)";
      gh release download $CTL_VERSION --pattern '*-linux' --output ~/.local/bin/flashctl --clobber --repo flash-tecnologia/flashstage.executable.flashctl;
      chmod +x ~/.local/bin/flashctl;
      readonly ADM_VERSION="$(gh release list --repo flash-tecnologia/flashstage.executable.flashadm | grep Latest | cut -f1 -)";
      gh release download $ADM_VERSION --pattern '*-linux' --output ~/.local/bin/flashadm --clobber --repo flash-tecnologia/flashstage.executable.flashadm;
      chmod +x ~/.local/bin/flashadm;
      
      readonly GH_TOKEN=$(gh auth token);
      if grep -q '^GH_TOKEN=' ~/.env 2>/dev/null; then
        sed -i 's/^GH_TOKEN=.*/GH_TOKEN='$GH_TOKEN'/' ~/.env;
      else
        echo 'GH_TOKEN='$GH_TOKEN >> ~/.env;
        chmod 600 ~/.env;
      fi
      export $GH_TOKEN;
    '';
  };

  code = with edgePkgs; let
    ide = vscode;
    cli = stdenvNoCC.mkDerivation rec {
      name = ide.name + "-cli";
      version = ide.version;
      
      passthru = rec {
        arch = {
          x86_64-linux = "x64";
          aarch64-linux = "arm64";
        }.${system} or throwSystem;
        sha256 = {
          x86_64-linux = "sha256-NVQaHzWo3Kiqa4Q2dKda1yB3rnTh3lVXMdrBof8xglg=";
          aarch64-linux = "sha256-JkD89PsaqdgDwvJy3n8YjTGTjcO+YKECGDrXpRMRoxE=";
        }.${system} or throwSystem;
        throwSystem = throw "Unsupported ${system} for ${name} v${version}";
      };
      
      src = fetchzip {
        extension = "tar.gz";
        sha256 = passthru.sha256;
        url = "https://update.code.visualstudio.com/${version}/cli-alpine-${passthru.arch}/stable";
      };
      
      phases = [ "unpackPhase" "installPhase" ];
      
      installPhase = ''
        mkdir -p $out/bin
        cp $src/code $out/bin
      '';
    };

    nodejs = nodejs_18;
    python = python311.withPackages (ps: with ps; [
      pip
      nbformat
      ipykernel
    ]);
  in writeShellApplication rec {
    name = "code";
    checkPhase = false;

    runtimeInputs = [
      python
      nodejs
    ];

    text = ''
      if [ -f "/usr/share/code/bin/code" ]; then
        ${cli}/bin/code version use stable --install-dir /usr/share/code >/dev/null;
      else
        ${lib.optionalString withUI "${cli}/bin/code version use stable --install-dir ${ide}/lib/vscode >/dev/null;"}
      fi
      exec ${cli}/bin/code "$@";
    '';
  };
  
  packages = with pkgs; let
    devbox = edgePkgs.devbox;
    huggingface-cli = python311.pkgs.huggingface-hub;
  in [
    code
    devbox
    steampipe
    
    gh
    tldr
    httpie
    git-crypt
    huggingface-cli
    
    dind
    goss
    dgoss
    using
    podman
    docker-client
    podman-compose
    docker-compose
  ] ++ pkgs.lib.optionals toWork [
    flash-install
  ];

in packages
