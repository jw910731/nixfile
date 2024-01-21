{pkgs, ...}: 
{
  home.packages = with pkgs; [
    # required by https://github.com/adi1090x/polybar-themes
    polybar # status bar

    dunst # notification daemon
    picom # transparency and shadows
    xsel # for clipboard support in x11, required by tmux's clipboard support

    dex # autostart applications
    xbindkeys # bind keys to commands
    xorg.xbacklight # control screen brightness, the same as light
    xorg.xdpyinfo # get screen information
  ];
}
