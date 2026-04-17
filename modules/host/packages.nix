{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    git
    git-lfs
    delta
    neovim
    vim
    nano
    openssl
    networkmanager
    iw
    wirelesstools
  ];
}
