{ ... }:
{
  imports = [
    ./secrets.nix
    ./ddns.nix
    ./acme.nix
    ./nginx.nix
  ];
}
