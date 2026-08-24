let
  caches = [
    "https://cache.nixos.org"
    "https://cache.numtide.com"
    "https://nix-community.cachix.org"
    "https://vicinae.cachix.org"
    "https://noctalia.cachix.org"
  ];
in
{
  nix.settings = {
    substituters = caches;
    trusted-substituters = caches;
    trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    ];
  };
}
