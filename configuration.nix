# {
#   inputs = {
#     nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
#   };

#   outputs = inputs@{ self, nixpkgs, ... }: {
#     nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
#       specialArgs = { inherit inputs; };
#       system = "x86_64-linux";
#       modules = [
#         ./configuration.nix
#       ];
#     };
#   };
# }

{ inputs, config, pkgs, ... }:
{
  system.stateVersion = "25.05";
  nixpkgs.config.allowUnfree = true;

  nix.settings.trusted-users = [ "root" "@wheel" ];
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  imports = [
    ./hardware-configuration.nix
  ];

  # Bootloader
  boot = {
    loader = {
      timeout = 0;
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    consoleLogLevel = 0;
    initrd.verbose = false;
    plymouth.enable = true;
    kernelParams = [
      "quiet"
      "splash"
      "loglevel=3"
      "udev.log_priority=3"
      "rd.udev.log_level=3"
      "boot.shell_on_fail"
      "rd.systemd.show_status=false"
    ];
  };

  # Configure console keymap
  console.keyMap = "br-abnt2";

  # Set your time zone.
  time.timeZone = "America/Sao_Paulo";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "pt_BR.UTF-8";
    LC_IDENTIFICATION = "pt_BR.UTF-8";
    LC_MEASUREMENT = "pt_BR.UTF-8";
    LC_MONETARY = "pt_BR.UTF-8";
    LC_NAME = "pt_BR.UTF-8";
    LC_NUMERIC = "pt_BR.UTF-8";
    LC_PAPER = "pt_BR.UTF-8";
    LC_TELEPHONE = "pt_BR.UTF-8";
    LC_TIME = "pt_BR.UTF-8";
  };

  # Enable networking
  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
  };
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };
  #services.tailscale = {
  #  enable = true;
  #  useRoutingFeatures = "client";
  #};
  services.cloudflare-warp.enable = true;

  # Enable bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  # Enable Plasma Desktop Environment.
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };
  services.desktopManager.plasma6.enable = true;

  programs.kde-pim = {
    enable = true;
    kmail = true;
    kontact = true;
    merkuro = true;
  };
  programs.kdeconnect.enable = true;

  # Enable print service with CUPS.
  services.printing = {
    enable = true;
    drivers = [
      pkgs.epson-escpr
    ];
  };

  # Enable scan services with SANE.
  hardware.sane = {
    enable = true;
    extraBackends = [
      pkgs.sane-airscan
    ];
  };
  services.udev.packages = [
    pkgs.sane-airscan
  ];

  # Enable sound with pipewire.
  security.rtkit.enable = true;
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    jack.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
  };

  # Support for dynamically linked executables 
  programs.nix-ld.enable = true;

  # Support for virtualization
  virtualisation = {
    docker.enable = true;
    waydroid.enable = true;
    libvirtd.enable = true;
  };
  systemd.tmpfiles.rules =
    let
      firmware =
        pkgs.runCommandLocal "qemu-firmware" { } ''
          mkdir $out
          cp ${pkgs.qemu}/share/qemu/firmware/*.json $out
          substituteInPlace $out/*.json --replace-fail ${pkgs.qemu} /run/current-system/sw
        '';
    in #https://github.com/NixOS/nixpkgs/issues/115996#issuecomment-2224296279
    [ "L+ /var/lib/qemu/firmware - - - - ${firmware}" ];

  # System packages
  programs.zsh.enable = true;
  environment.systemPackages = with pkgs; [
    git
    qemu
    ecryptfs
    wl-clipboard
    qt6.qtwebengine
  ];

  # Base users environment
  users.users.rafael = {
    shell = pkgs.zsh;
    isNormalUser = true;
    description = "Rafael Oliveira";
    extraGroups = [ "networkmanager" "lp" "scanner" "docker" "wheel" ];
    packages = with pkgs; [
      #tailscale-systray
      kdePackages.yakuake
      kdePackages.kdepim-addons
    ];
  };
}
