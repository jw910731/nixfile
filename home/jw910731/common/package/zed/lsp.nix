{
  clangd.binary.arguments = [
    "--query-driver"
    "/nix/store/*/bin/*gcc"
    "--query-driver"
    "/nix/store/*/bin/*clang"
    "--query-driver"
    "/nix/store/*/bin/*g++"
    "--query-driver"
    "/nix/store/*/bin/*clang++"
  ];
}
