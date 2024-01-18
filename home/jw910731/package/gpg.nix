{pkgs, ...}:
{
  programs.gpg = {
    enable = true;
    package = pkgs.gnupg;

    publicKeys = [
      {
        text = "-----BEGIN PGP PUBLIC KEY BLOCK-----

mDMEYv+kuxYJKwYBBAHaRw8BAQdAKf+6l5bNhtq9gWOhsYnt0t2rGseXk1eT7Gs0
WALI+Uu0IeWQs+aWh+WFgyA8NDA5NDcwMzBTQG50bnUuZWR1LnR3PoiWBBMWCAA+
FiEEqYjGSP+546/7a4CJQFdzRADtoU4FAmL/po0CGwMFCQlmAYAFCwkIBwIGFQoJ
CAsCBBYCAwECHgECF4AACgkQQFdzRADtoU4XFQEA0HC9sXThCYEjd9YlpV/RQC1S
dImN2rerS9MIM/ZltcUBALWPwBAVtOHCzF6LONjoD5V7cmIbjOS/F78dd+yOD2cI
tCflkLPmloflhYMgPGp3OTEwNzMxQG50bnUuZWR1LnR3PiAoTlROVSmIlgQTFggA
PhYhBKmIxkj/ueOv+2uAiUBXc0QA7aFOBQJi/6YYAhsDBQkJZgGABQsJCAcCBhUK
CQgLAgQWAgMBAh4BAheAAAoJEEBXc0QA7aFOFSUBANqmwWCQ1k2Hd2tScTtgN+9C
xhWKGrNOShZwQz+DIPYCAQDfufk6a//8eTQ5PMXzTdwRNpn874BnZGoKP/rIFeVm
A7Qe5ZCz5paH5YWDIDxqdzkxMDczMUBnbWFpbC5jb20+iJYEExYIAD4WIQSpiMZI
/7njr/trgIlAV3NEAO2hTgUCYv+kuwIbAwUJCWYBgAULCQgHAgYVCgkICwIEFgID
AQIeAQIXgAAKCRBAV3NEAO2hTr6MAP9zM5v0nEWu1DnWLATomNv5t33rnuOY/GU7
jPs9v8tmFQD+I8S7h1EGmcES7UaLxvF/q34Iy5g2BpelkG/jz1QYkAK4MwRi/6S7
FgkrBgEEAdpHDwEBB0CBS6ZsNfyzKmfl/pRHHsRpJKHctDbwRq6+4MsojqeL3Yh+
BBgWCAAmFiEEqYjGSP+546/7a4CJQFdzRADtoU4FAmL/pLsCGyAFCQlmAYAACgkQ
QFdzRADtoU6nDQD8C333HudcKJudfMc+TEpZr2S1Fp61qF5aWSwOCURDHRQBAKao
gxG3i2voJx1notqLfASxpzns+mSEoEHnxnVJTCsHuDgEYv+kuxIKKwYBBAGXVQEF
AQEHQA7QZdCWg4ctUDG7RWxLtXXeWtaOg8uy7uhYdUd7eH0NAwEIB4h+BBgWCAAm
FiEEqYjGSP+546/7a4CJQFdzRADtoU4FAmL/pLsCGwwFCQlmAYAACgkQQFdzRADt
oU4kZAD/TyoddyyO6mnkrk3vsYxCBeXPTz5zsgT0OuFoAAd9OsYA/3zg8Hd8S9jA
HmYkbYL+G1V+N1UnMasb7YeVxtxOVzEH
=PwKy
-----END PGP PUBLIC KEY BLOCK-----
";
      }
    ];

    settings ={
      keyserver = "hkp://keyserver.ubuntu.com";
    };
  };

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    enableExtraSocket = true;
    enableZshIntegration = true;
    pinentryFlavor = "qt";
  };
}