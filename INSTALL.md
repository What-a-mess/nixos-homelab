# NixOS Homelab Installation Guide

This repository installs the `homelab` NixOS host defined in [`flake.nix`](/home/wamess/tech-stuff/nixos-server/flake.nix).

## Prerequisites

- A machine booted from the official NixOS installer ISO
- UEFI boot mode enabled
- Internet access during install
- This repository available locally or via Git remote

This configuration expects:

- An EFI system partition labeled `boot`
- A btrfs system partition labeled `nixos`
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
parted /dev/sda -- mkpart nixos btrfs 512MiB 100GiB
parted /dev/sda -- mkpart homelab-data ext4 100GiB 100%

mkfs.fat -F 32 -n boot /dev/sda1
mkfs.btrfs -L nixos /dev/sda2
mkfs.ext4 -L homelab-data /dev/sda3
```

If you use a separate data disk, only the labels matter. The host configuration mounts `/srv/data` from `/dev/disk/by-label/homelab-data`.

## 3. Mount the Target Filesystems

```bash
mount /dev/disk/by-label/nixos /mnt
btrfs subvolume create /mnt/@root
btrfs subvolume create /mnt/@nix
btrfs subvolume create /mnt/@log
umount /mnt

mount -o subvol=@root,compress=zstd /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/nix
mount -o subvol=@nix,compress=zstd /dev/disk/by-label/nixos /mnt/nix
mkdir -p /mnt/var/log
mount -o subvol=@log,compress=zstd /dev/disk/by-label/nixos /mnt/var/log
mkdir -p /mnt/boot
mount /dev/disk/by-label/boot /mnt/boot
mkdir -p /mnt/srv/data
mount /dev/disk/by-label/homelab-data /mnt/srv/data
```

This layout uses three btrfs subvolumes on the system partition:

- `@root` mounted at `/`
- `@nix` mounted at `/nix`
- `@log` mounted at `/var/log`

`/boot` remains a FAT32 EFI system partition, and the bulk-data disk remains `ext4`.

## 4. Generate Hardware Configuration

Generate hardware-specific settings for the target machine:

```bash
nixos-generate-config --root /mnt
```

Do not reuse the repository's existing `hosts/homelab/hardware-configuration.nix` on a different machine without regenerating it.

After generating the file, ensure it retains this repository's intended filesystem layout:

- `/` mounted from the btrfs subvolume `@root`
- `/nix` mounted from the btrfs subvolume `@nix`
- `/var/log` mounted from the btrfs subvolume `@log`
- `/boot` mounted from the FAT32 EFI partition labeled `boot`

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

If the generated hardware configuration does not already include the expected btrfs subvolume mounts, edit `hosts/homelab/hardware-configuration.nix` before running `nixos-install`.

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
- This repository defines MicroVM workloads for `storage-vm`, `media-vm`, and `app-vm`.
- Review user, SSH, and secret management before exposing the host to a network.

## Application Tier Notes

- `app-vm` is the default execution boundary for RSSHub and similar lightweight application services.
- The first RSSHub deployment uses the official `chromium-bundled` image so browser automation support stays inside `app-vm` without a separate browserless sidecar.
- No dedicated ingress layer is included yet; `app-vm` services are exposed through host-managed port forwarding.
- Future services belong in `app-vm` only if they fit the same lightweight application-service boundary and do not require the shared media data model used by `media-vm`.

## Validation After First Boot

Run these checks on the installed system:

```bash
hostnamectl
findmnt /
findmnt /boot
findmnt /srv/data
systemctl status microvm@storage-vm
systemctl status microvm@media-vm
systemctl status microvm@app-vm
curl -I http://127.0.0.1:1200
```

If a MicroVM fails to start, inspect:

```bash
journalctl -u microvm@storage-vm -b
journalctl -u microvm@media-vm -b
journalctl -u microvm@app-vm -b
```
