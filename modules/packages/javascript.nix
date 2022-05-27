pkgs: with pkgs; [
  (yarn.override { nodejs = null; })
]
