{ config, pkgs, ... }:
{
  system.stateVersion = "24.05";
  nixpkgs.config.allowUnfree = true;
  nix.settings.trusted-users = [ "root" "@wheel" ];

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

  # Enable bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  # Enable the GNOME Desktop Environment.
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  services.xserver.xkb = {
    layout = "br";
    variant = "";
  };

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
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    jack.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
  };

  # Support for dynamically linked executables 
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
    ];
  };

  # Support for virtualization
  virtualisation = {
    docker.enable = true;
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
  programs.steam.enable = true;
  environment.systemPackages = with pkgs; [
    qemu
    ecryptfs
    gst_all_1.gstreamer
    gst_all_1.gst-libav
    gst_all_1.gst-vaapi
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
  ];

  # Base users environment
  users.users.rafael = {
    shell = pkgs.zsh;
    isNormalUser = true;
    description = "Rafael Oliveira";
    extraGroups = [ "networkmanager" "scanner" "lp" "wheel" "docker" ];
    packages = with pkgs; [
      gnome.gnome-sound-recorder
      gnome.gnome-boxes
    ];
  };
}

