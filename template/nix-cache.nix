let
  caches = [
    "https://cache.nixos.org"
    "https://cache.numtide.com"
  ];
in
{
  nix.settings = {
    substituters = caches;
    trusted-substituters = caches;
    trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };
}
