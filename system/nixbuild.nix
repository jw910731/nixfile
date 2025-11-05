{
  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];
  hostName = "eu.nixbuild.net";
  protocol = "ssh-ng";
  maxJobs = 100;
  supportedFeatures = [
    "big-parallel"
    "benchmark"
    "kvm"
    "nixos-test"
  ];
}
