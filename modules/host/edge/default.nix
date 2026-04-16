{ ... }:
{
  imports = [
    ./options.nix
    ./secrets.nix
    ./ddns.nix
    ./acme.nix
    ./pki.nix
    ./caddy.nix
    ./nginx.nix
  ];
}
