{ pkgs, config, ... }:

{
  environment.systemPackages = with pkgs; [
    bashInteractive
    cmake
    openssh
    screen
    zsh
    wget
  ];

  services.emacs = {
    enable = true;
    package = pkgs.emacs-nox;
  };

  launchd.agents.numlockfixd = {
    path = [ config.environment.systemPath ];
    serviceConfig = {
      ProgramArguments = [ "${pkgs.numlockfixd}/bin/numlockfixd" ];
      RunAtLoad = true;
      KeepAlive = true;
    };
  };
}
