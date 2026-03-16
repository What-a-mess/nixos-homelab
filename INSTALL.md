# NixOS Homelab Installation Guide

This repository installs the `homelab` NixOS host defined in [`flake.nix`](/home/wamess/tech-stuff/nixos-server/flake.nix).

## Prerequisites

- A machine booted from the official NixOS installer ISO
- UEFI boot mode enabled
- Internet access during install
- This repository available locally or via Git remote

This configuration expects:

- An EFI system partition labeled `boot`
- A root filesystem labeled `nixos`
- A data filesystem labeled `homelab-data`

## 1. Boot the Installer

Boot the official NixOS `x86_64-linux` installer in UEFI mode.

Confirm the target disks before formatting:

```bash
lsblk -o NAME,SIZE,TYPE,FSTYPE,LABEL,MOUNTPOINT
```

## 2. Partition and Format the Disks

The example below uses a single disk at `/dev/sda`. Adjust device names and sizes to match the target machine.

```bash
parted /dev/sda -- mklabel gpt
parted /dev/sda -- mkpart ESP fat32 1MiB 512MiB
parted /dev/sda -- set 1 esp on
parted /dev/sda -- mkpart nixos ext4 512MiB 100GiB
parted /dev/sda -- mkpart homelab-data ext4 100GiB 100%

mkfs.fat -F 32 -n boot /dev/sda1
mkfs.ext4 -L nixos /dev/sda2
mkfs.ext4 -L homelab-data /dev/sda3
```

If you use a separate data disk, only the labels matter. The host configuration mounts `/srv/data` from `/dev/disk/by-label/homelab-data`.

## 3. Mount the Target Filesystems

```bash
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount /dev/disk/by-label/boot /mnt/boot
mkdir -p /mnt/srv/data
mount /dev/disk/by-label/homelab-data /mnt/srv/data
```

## 4. Generate Hardware Configuration

Generate hardware-specific settings for the target machine:

```bash
nixos-generate-config --root /mnt
```

Do not reuse the repository's existing `hosts/homelab/hardware-configuration.nix` on a different machine without regenerating it.

## 5. Copy the Repository into the Target System

If cloning from a remote:

```bash
git clone <repo-url> /mnt/etc/nixos
```

If copying from local media:

```bash
mkdir -p /mnt/etc
cp -a /path/to/nixos-homelab /mnt/etc/nixos
```

Then replace the repository's hardware config with the generated one:

```bash
cp /mnt/hardware-configuration.nix /mnt/etc/nixos/hosts/homelab/hardware-configuration.nix
```

## 6. Install the System from the Flake

```bash
cd /mnt/etc/nixos
nixos-install --flake .#homelab
```

Because this repository does not pin a `flake.lock`, the installer must be able to fetch `nixpkgs` and `microvm.nix` over the network.

## 7. Reboot

```bash
reboot
```

Remove the installer media when prompted.

## Post-Install Notes

- The host bootloader is `systemd-boot` in UEFI mode.
- The host mounts `/srv/data` from the `homelab-data` filesystem.
- This repository defines MicroVM workloads for `storage-vm` and `media-vm`.
- Review user, SSH, and secret management before exposing the host to a network.

## Validation After First Boot

Run these checks on the installed system:

```bash
hostnamectl
findmnt /
findmnt /boot
findmnt /srv/data
systemctl status microvm@storage-vm
systemctl status microvm@media-vm
```

If a MicroVM fails to start, inspect:

```bash
journalctl -u microvm@storage-vm -b
journalctl -u microvm@media-vm -b
```
