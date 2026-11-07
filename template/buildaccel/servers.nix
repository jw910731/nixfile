{
  macstudio = {
    hostName = "jw910731-Mac-Studio";
    address = "jw910731-Mac-Studio.local";
    port = 3632;
    systems = [ "aarch64-linux" ];
    slots = 8;
    vm = {
      # QEMU's virt machine with GICv2 (what the builder VM uses on HVF) caps at 8 vCPUs.
      cores = 8;
      memorySize = 12288;
    };
  };
  macmini = {
    hostName = "MacMini";
    address = "MacMini.local";
    port = 3632;
    systems = [ "aarch64-linux" ];
    slots = 8;
    vm = {
      cores = 8;
      memorySize = 8192;
    };
  };
}
