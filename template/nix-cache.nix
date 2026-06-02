let
  caches = [
    "https://nixos-apple-silicon.cachix.org"
    "https://claude-code.cachix.org"
  ];
in
{
  nix.settings = {
    substituters = caches;
    trusted-substituters = caches;
    trusted-public-keys = [
      "nixos-apple-silicon.cachix.org-1:8psDu5SA5dAD7qA0zMy5UT292TxeEPzIz8VVEr2Js20="
      "claude-code.cachix.org-1:YeXf2aNu7UTX8Vwrze0za1WEDS+4DuI2kVeWEE4fsRk="
    ];
  };
}
