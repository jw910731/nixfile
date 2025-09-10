{ pkgs, lib, ... }:
let
  cfg = {
    package = pkgs.antidote;
    plugins = [
      "zsh-users/zsh-autosuggestions"
      "romkatv/powerlevel10k"
      "zsh-users/zsh-history-substring-search"
      "wfxr/forgit"
      "ohmyzsh/ohmyzsh path:plugins/git kind:defer"
      "MichaelAquilina/zsh-you-should-use"
      "Aloxaf/fzf-tab"
      "zsh-users/zsh-syntax-highlighting kind:defer"
      "greymd/docker-zsh-completion"
      "sunlei/zsh-ssh"
    ];
  };
  zPluginStr = (
    pluginNames:
    lib.optionalString (pluginNames != [ ])
      "${lib.concatStrings (
        map (name: ''
          ${name}
        '') pluginNames
      )}"
  );

  parseHashId = path: lib.elemAt (builtins.match "${builtins.storeDir}/([a-zA-Z0-9]+)-.*" path) 0;
in
{
  home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];
  programs.zsh.initContent =
    let
      configFiles = pkgs.runCommand "hm_antidote-files" { } ''
        echo "${zPluginStr cfg.plugins}" > $out
      '';
      hashId = parseHashId "${configFiles}";
    in
    (lib.mkOrder 550 ''
      ## home-manager/antidote begin :
      source ${cfg.package}/share/antidote/antidote.zsh
      ${lib.optionalString cfg.useFriendlyNames "zstyle ':antidote:bundle' use-friendly-names 'yes'"}

      bundlefile=${configFiles}
      zstyle ':antidote:bundle' file $bundlefile
      staticfile=/tmp/tmp_hm_zsh_plugins.zsh-${hashId}
      zstyle ':antidote:static' file $staticfile

      antidote load $bundlefile $staticfile

      ## home-manager/antidote end
    '');
}
