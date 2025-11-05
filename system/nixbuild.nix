{
  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];
  hostName = "eu.nixbuild.net";
  protocol = "ssh-ng";
  maxJobs = 16;
  supportedFeatures = [
    "big-parallel"
    "benchmark"
    "kvm"
    "nixos-test"
  ];
}
