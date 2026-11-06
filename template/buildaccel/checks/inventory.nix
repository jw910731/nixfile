{ pkgs, ... }:
let
  inv = import ../inventory.nix { inherit (pkgs) lib; };
  valid = {
    hostName = "x";
    address = "x";
    port = 1;
    systems = [ "aarch64-linux" ];
    slots = 1;
    vm = {
      cores = 1;
      memorySize = 1;
    };
  };
  rejects = value: !(builtins.tryEval (builtins.deepSeq (inv.validate value) true)).success;
in
assert inv.validate inv.servers == inv.servers;
assert rejects {
  x = valid // {
    slots = 0;
  };
};
assert rejects { Bad_Name = valid; };
assert rejects { x = builtins.removeAttrs valid [ "vm" ]; };
assert rejects {
  x = valid // {
    vm = {
      memorySize = 1;
    };
  };
};
assert rejects {
  x = valid // {
    vm = {
      cores = 1;
    };
  };
};
assert rejects {
  x = valid // {
    systems = [ "riscv64-linux" ];
  };
};
assert
  builtins.attrNames (inv.forSystem "aarch64-linux" inv.servers) == [
    "macmini"
    "macstudio"
  ];
assert inv.forSystem "x86_64-linux" inv.servers == { };
assert inv.byHostName "MacMini" inv.servers == "macmini";
assert inv.byHostName "jw910731-Mac-Studio" inv.servers == "macstudio";
assert inv.byHostName "unknown-mac" inv.servers == null;
pkgs.runCommand "buildaccel-check-inventory" { } "echo ok > $out"
