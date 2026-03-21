{
  description = "Declarative single-host homelab with microVM service groups";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    microvm.url = "github:microvm-nix/microvm.nix";
    microvm.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nixpkgs, microvm, ... }:
    let
      system = "x86_64-linux";
      homelab = import ./lib/homelab-config.nix;

      mkSystem = modules:
        nixpkgs.lib.nixosSystem {
          inherit system modules;
          specialArgs = {
            inherit self homelab;
            microvmModules = microvm.nixosModules;
          };
        };
    in {
      nixosConfigurations = {
        homelab = mkSystem [
          ./hosts/homelab
        ];

        storage-vm = mkSystem [
          microvm.nixosModules.microvm
          ./vms/storage-vm.nix
        ];

        media-vm = mkSystem [
          microvm.nixosModules.microvm
          ./vms/media-vm.nix
        ];
      };
    };
}
