let
  caches = [
    "https://cache.garnix.io"
    "https://nixos-apple-silicon.cachix.org"
  ];
in {
  nix.settings = {
    substituters = caches;
    trusted-substituters = caches;
    trusted-public-keys = [
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      "nixos-apple-silicon.cachix.org-1:8psDu5SA5dAD7qA0zMy5UT292TxeEPzIz8VVEr2Js20="
    ];
  };
}
