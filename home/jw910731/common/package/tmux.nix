{
  programs.tmux = {
    enable = true;
    baseIndex = 1;
    mouse = true;
    extraConfig = ''
      allow-passthrough = on
    '';
  };
}
