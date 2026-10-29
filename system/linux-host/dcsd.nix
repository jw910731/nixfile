{ config, pkgs, ... }:
{
  # FTDI DCSD USB UART cables -> /dev/dcsd + serial login on every plug-in
  services.udev.extraRules = ''
    SUBSYSTEM=="tty", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6001", ATTRS{serial}=="A106WWY1", SYMLINK+="dcsd", OPTIONS+="link_priority=20", ENV{ID_MM_DEVICE_IGNORE}="1", TAG+="systemd", ENV{SYSTEMD_WANTS}+="serial-getty@dcsd.service"
    SUBSYSTEM=="tty", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6001", ATTRS{serial}=="AU00JXMF", SYMLINK+="dcsd", OPTIONS+="link_priority=10", ENV{ID_MM_DEVICE_IGNORE}="1", TAG+="systemd", ENV{SYSTEMD_WANTS}+="serial-getty@dcsd.service"
  '';

  # Instance drop-in only. Its overrides.conf shadows the template's, so the
  # ExecStart reset and restartIfChanged must be restated here. No --keep-baud:
  # it would keep the ttyUSB default of 9600.
  systemd.services."serial-getty@dcsd" = {
    overrideStrategy = "asDropin";
    restartIfChanged = false;
    unitConfig.StartLimitIntervalSec = 0;
    serviceConfig = {
      RestartSec = 1;
      ExecStart = [
        ""
        "${pkgs.util-linux}/bin/agetty --login-program ${config.services.getty.loginProgram} --issue-file /etc/issue:/etc/issue.d:/run/issue:/run/issue.d %I 115200,57600,38400,9600 $TERM"
      ];
    };
  };
}
