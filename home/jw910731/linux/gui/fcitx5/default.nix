{ config, pkgs, ... }:
{
  home.file.".local/share/fcitx5/rime/default.custom.yaml".source = ./default.custom.yaml;

  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      waylandFrontend = true;
      addons = with pkgs; [
        rime-data
        fcitx5-rime
        qt6Packages.fcitx5-configtool
      ];
    };
  };

  xdg.configFile = {
    "fcitx5/profile" = {
      source = ./profile;
      # every time fcitx5 switch input method, it will modify ~/.config/fcitx5/profile,
      # so we need to force replace it in every rebuild to avoid file conflict.
      force = true;
    };
    "fcitx5/config" = {
      source = ./config;
      # every time fcitx5 switch input method, it will modify ~/.config/fcitx5/profile,
      # so we need to force replace it in every rebuild to avoid file conflict.
      force = true;
    };
    "fcitx5/conf/classicui.conf".source = ./classicui.conf;
  };

  # nix store 檔案 mtime 恆為 epoch，librime 以 mtime 判斷 custom 檔是否變更，
  # 會永遠認為沒變而不重新編譯；每次 switch 強制作廢編譯快取（重啟 fcitx5 後生效）
  home.activation.rimeForceRecompile = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD rm -f "$HOME/.local/share/fcitx5/rime/build/default.yaml" \
      "$HOME/.local/share/fcitx5/rime/build/"*.schema.yaml
  '';

}
