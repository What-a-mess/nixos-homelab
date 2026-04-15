{ lib, ... }:
{
  imports = [
    ./secrets.nix
    ./ddns.nix
    ./acme.nix
    ./pki.nix
  ] ++ lib.optionals (builtins.pathExists ./caddy.nix) [
    ./caddy.nix
  ] ++ [
    ./nginx.nix
  ];
}
