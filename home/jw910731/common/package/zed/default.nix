{ ... }:
{
  programs.zed-editor = let
    extentions = import ./extensions.nix;
    terminal = import ./terminal.nix;
    lsp = import ./lsp.nix;
    settings = import ./settings.nix;
  in {
    extensions = extentions;
    userSettings =
      settings
      // {
        terminal = terminal;
        lsp = lsp;
      };
  };
}
