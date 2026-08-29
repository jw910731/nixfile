{ pkgs, ... }:
{
  home.packages = with pkgs; [
    pkgs.llm-agents.claude-desktop
  ];
  services.flatpak.packages = [
    "com.bitwig.BitwigStudio"
  ];
}
