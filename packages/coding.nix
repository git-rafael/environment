pkgs:

let
	packages = with pkgs; [
		slack
		discord
		spotify

		vscode
	];

in packages
