pkgs: with pkgs; [
  fnm
  (yarn.override { nodejs = null; })
]
