{ pkgs, inputs, ... }:
let
  llm-agents = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
in {
  home.packages = with pkgs; [
    llm-agents.claude-desktop
  ];
  services.flatpak.packages = [
    "com.bitwig.BitwigStudio"
  ];
}
