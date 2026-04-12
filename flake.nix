{
  description = "Declarative single-host homelab with microVM service groups";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    microvm.url = "github:microvm-nix/microvm.nix";
    microvm.inputs.nixpkgs.follows = "nixpkgs";
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    vscode-server.url = "github:nix-community/nixos-vscode-server";
    vscode-server.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nixpkgs, microvm, agenix, vscode-server, ... }:
    let
      system = "x86_64-linux";
      homelab = import ./lib/homelab-config.nix;

      mkSystem = modules:
        nixpkgs.lib.nixosSystem {
          inherit system modules;
          specialArgs = {
            inherit self homelab;
            microvmModules = microvm.nixosModules;
            inherit vscode-server;
          };
        };
    in {
      nixosConfigurations = {
        homelab = mkSystem [
          agenix.nixosModules.default
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

        app-vm = mkSystem [
          microvm.nixosModules.microvm
          ./vms/app-vm.nix
        ];
      };
    };
}
