{ pkgs, ... }:
{
  programs.github-copilot-cli = {
    enable = true;
    package = pkgs.llm-agents.copilot-cli;   
  };
}