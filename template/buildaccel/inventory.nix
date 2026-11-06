{ lib }:
let
  namePattern = builtins.match "[a-z][a-z0-9-]{0,31}";
  validate =
    servers:
    let
      checks = lib.mapAttrsToList (
        name: server:
        let
          missing = builtins.filter (field: !(builtins.hasAttr field server)) [
            "hostName"
            "address"
            "port"
            "systems"
            "slots"
            "vm"
          ];
          fail = field: message: throw "buildaccel inventory: entry '${name}': field '${field}' ${message}";
          missingVmFields =
            if server ? vm && builtins.isAttrs server.vm then
              builtins.filter (field: !(builtins.hasAttr field server.vm)) [
                "cores"
                "memorySize"
              ]
            else
              [ ];
          systemErrors = builtins.filter (
            system:
            !(builtins.elem system [
              "aarch64-linux"
              "x86_64-linux"
            ])
          ) (server.systems or [ ]);
        in
        if missing != [ ] then
          fail (builtins.head missing) "is required"
        else if missingVmFields != [ ] then
          fail "vm.${builtins.head missingVmFields}" "is required"
        else if namePattern name == null then
          fail "name" "does not match the required pattern"
        else if server.slots < 1 then
          fail "slots" "must be at least 1"
        else if systemErrors != [ ] then
          fail "systems" "has unsupported value '${builtins.head systemErrors}'"
        else
          true
      ) servers;
    in
    builtins.seq (builtins.deepSeq checks true) servers;
in
{
  servers = import ./servers.nix;
  inherit validate;
  forSystem =
    system: servers: lib.filterAttrs (_: server: builtins.elem system server.systems) servers;
  byHostName =
    hostName: servers:
    let
      matches = lib.filterAttrs (_: server: server.hostName == hostName) servers;
    in
    if matches == { } then null else builtins.head (builtins.attrNames matches);
}
