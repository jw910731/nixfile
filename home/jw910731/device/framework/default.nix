{ pkgs, ... }:
{
  home.packages = with pkgs; [
    pkgs.llm-agents.claude-desktop
    pkgs.llm-agents.chatgpt
  ];
  services.flatpak.packages = [
    "com.bitwig.BitwigStudio"
  ];
}
