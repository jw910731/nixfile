{ lib, ... }:
{
  imports = [
    ./i3
  ];

  xsession = {
    enable = true;
    scriptPath = ".hm-xsession";
  };

}
