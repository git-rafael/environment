{ pkgs, features, inputs, ... }:

let
  withUI = builtins.elem "ui" features;
in
if !withUI then {} else {
  imports = [
    inputs.plasma-manager.homeModules.plasma-manager
    ./ui-settings.nix
  ];

  # overrideConfig = false means only declared keys are managed.
  # Changes made via the Plasma UI to non-declared keys persist across
  # `env-load` runs. Declared keys are rewritten on every rebuild.
  programs.plasma.overrideConfig = false;
}
