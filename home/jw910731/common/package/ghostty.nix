{ pkgs, ... }:
{
  programs.ghostty = {
    enable = true;
    enableZshIntegration = true;
    # installBatSyntax = true;
    settings = {
      language = "zh_TW";
      theme = "Atom One Dark";
      background-opacity = 0.95;
      font-family = [ "Hack Nerd Font Mono" "Noto Sans Mono CJK TC" ];
      font-size = 14;
      font-thicken = true;
      faint-opacity = 0.75;
      scrollback-limit = 104857600;
      shell-integration-features = "no-cursor,sudo,title,ssh-env";
      app-notifications = "no-clipboard-copy";
      cursor-style = "block";
      cursor-opacity = 0.65;
      working-directory = "home";
      window-inherit-working-directory = false;

      # Notification
      notify-on-command-finish-action = "no-bell,notify";
      notify-on-command-finish = "unfocused";

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
