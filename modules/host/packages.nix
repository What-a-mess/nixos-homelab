{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    git
    git-lfs
    delta
    neovim
    vim
    nano
    networkmanager
    iw
    wirelesstools
  ];
}
