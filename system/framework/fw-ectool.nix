{
  stdenv,
  lib,
  fetchFromGitHub,
  cmake,
  pkg-config,
  libusb1,
  libftdi1,
}:

stdenv.mkDerivation {
  pname = "fw-ectool";
  version = "v0.0.2";

  src = fetchFromGitHub {
    owner = "DHowett";
    repo = "ectool";
    rev = "v0.0.2";
    hash = "sha256-FTW770CEos8PvTrhmYZrX8cCg9vNCLL0DP/k24LR1QA=";
  };

  postPatch = ''
    substituteInPlace CMakeLists.txt --replace-fail \
      'cmake_minimum_required(VERSION 3.5)' \
      'cmake_minimum_required(VERSION 4.0)'
  '';

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
    libusb1
    libftdi1
  ];

  installPhase = ''
    runHook preInstall
    install -Dm555 src/ectool "$out/bin/ectool"
    runHook postInstall
  '';

  meta = {
    description = "EC-Tool adjusted for usage with framework embedded controller";
    homepage = "https://github.com/DHowett/ectool";
    license = lib.licenses.bsd3;
    platforms = lib.platforms.linux;
    mainProgram = "ectool";
  };
}