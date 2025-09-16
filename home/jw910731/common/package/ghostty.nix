{ pkgs, ... }:
{
  programs.ghostty = {
    enable = true;
    enableZshIntegration = true;
    # installBatSyntax = true;
    settings = {
      theme = "Atom One Dark";
      background-opacity = 0.95;
      font-family = "Hack Nerd Font Mono";
      font-size = 14;
      font-thicken = true;
      faint-opacity = 0.75;
      scrollback-limit = 20000;
      shell-integration-features = "no-cursor,sudo,title,ssh-env";
      app-notifications =  "no-clipboard-copy";
      cursor-style = "block";
      cursor-opacity = 0.65;

      # Mac OS Config
      macos-titlebar-style = "native";
      macos-option-as-alt = true;
      macos-icon = "glass";
      macos-shortcuts = "allow";
      macos-dock-drop-behavior = "window";
      macos-non-native-fullscreen = false;
    };
  };
}