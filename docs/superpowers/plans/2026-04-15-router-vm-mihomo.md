# Router VM Mihomo Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a dedicated `router-vm` that runs `mihomo` as a route node and ordinary proxy endpoint, using a host-local mounted config directory and bootstrap-safe startup when the config file is absent.

**Architecture:** Extend the existing microVM topology with a fourth VM on the same bridged LAN, give it a fixed IP, mount a host-local `mihomo` config directory into the guest, and gate the `mihomo` service on the presence of `config.yaml`. Keep the host responsible for VM lifecycle and bridge networking while `router-vm` owns proxy, forwarding, and TUN behavior.

**Tech Stack:** NixOS, microvm.nix, systemd-networkd, bridged tap networking, `services.mihomo`, host-local mounted config directories, Markdown docs

---

## File Structure

Planned file changes and responsibilities:

- Modify: `lib/homelab-config.nix`
  Add shared constants for `router-vm`, including IP, CPU, memory, and host/guest config paths.
- Modify: `modules/host/microvm-host.nix`
  Register `router-vm` with the microVM host.
- Create: `vms/router-vm.nix`
  Compose the router VM from focused router modules.
- Create: `modules/router-vm/identity.nix`
  Set hostname, static LAN identity, and base system identity.
- Create: `modules/router-vm/microvm.nix`
  Define the bridged tap NIC, state volume, and host-local config directory share.
- Create: `modules/router-vm/networking.nix`
  Enable IP forwarding, minimal firewall rules, and basic route-node prerequisites.
- Create: `modules/router-vm/mihomo.nix`
  Configure `services.mihomo`, point it at the mounted config file, and skip startup when the file is absent.
- Create: `modules/router-vm/state.nix`
  Create persistent directories used by `mihomo`.
- Modify: `docs/operations/architecture-map.md`
  Add `router-vm` to the VM boundary map.
- Modify: `docs/operations/services.md`
  Add `router-vm` and its config/runtime entry points.
- Modify: `docs/operations/first-boot.md`
  Add `router-vm` health checks and config-absent expected behavior.
- Create: `docs/operations/router-vm.md`
  Document operator workflow, local config placement, and client usage.

## Task 1: Add Shared Router VM Constants

**Files:**
- Modify: `lib/homelab-config.nix`

- [ ] **Step 1: Write the failing config lookup check**

Run:

```bash
rg -n "routerVm|192\\.168\\.31\\.214|/srv/data/router/mihomo|/var/lib/router-vm/mihomo-config" lib/homelab-config.nix
```

Expected: FAIL because `routerVm` does not exist yet.

- [ ] **Step 2: Add the shared router VM config block**

Update `lib/homelab-config.nix` by adding this block after `appVm`:

```nix
  routerVm = {
    memory = 2048;
    vcpu = 2;
    address = "192.168.31.214";
    configHostPath = "/srv/data/router/mihomo";
    configGuestPath = "/var/lib/router-vm/mihomo-config";
    stateVolume = {
      image = "/srv/data/vmstate/router-vm-state.img";
      mountPoint = "/var/lib/router-vm";
      size = 8192;
      fsType = "ext4";
      label = "router-vm-state";
    };
  };
```

- [ ] **Step 3: Re-run the config lookup check**

Run:

```bash
rg -n "routerVm|192\\.168\\.31\\.214|/srv/data/router/mihomo|/var/lib/router-vm/mihomo-config" lib/homelab-config.nix
```

Expected: PASS with matches for the new `routerVm` block and paths.

- [ ] **Step 4: Commit**

```bash
git add lib/homelab-config.nix
git commit -m "feat: add router-vm shared config"
```

## Task 2: Register And Compose Router VM

**Files:**
- Modify: `modules/host/microvm-host.nix`
- Create: `vms/router-vm.nix`

- [ ] **Step 1: Write the failing router VM registry check**

Run:

```bash
rg -n "router-vm" modules/host/microvm-host.nix vms/router-vm.nix
```

Expected: FAIL because neither file contains `router-vm` yet.

- [ ] **Step 2: Register `router-vm` in the host microVM map**

Update `modules/host/microvm-host.nix` so the `microvm.vms` attrset includes:

```nix
    router-vm = {
      flake = self;
    };
```

The full block should read:

```nix
  microvm.vms = {
    storage-vm = {
      flake = self;
    };

    media-vm = {
      flake = self;
    };

    app-vm = {
      flake = self;
    };

    router-vm = {
      flake = self;
    };
  };
```

- [ ] **Step 3: Create the router VM entrypoint**

Create `vms/router-vm.nix` with this content:

```nix
{
  imports = [
    ../modules/router-vm/identity.nix
    ../modules/router-vm/microvm.nix
    ../modules/router-vm/networking.nix
    ../modules/router-vm/mihomo.nix
    ../modules/router-vm/state.nix
  ];
}
```

- [ ] **Step 4: Re-run the router VM registry check**

Run:

```bash
rg -n "router-vm" modules/host/microvm-host.nix vms/router-vm.nix
```

Expected: PASS with matches in both files.

- [ ] **Step 5: Commit**

```bash
git add modules/host/microvm-host.nix vms/router-vm.nix
git commit -m "feat: register router-vm entrypoint"
```

## Task 3: Add Router VM Identity And Static LAN Address

**Files:**
- Create: `modules/router-vm/identity.nix`

- [ ] **Step 1: Write the failing existence check**

Run:

```bash
test -f modules/router-vm/identity.nix
```

Expected: FAIL because the file does not exist yet.

- [ ] **Step 2: Create the identity module**

Create `modules/router-vm/identity.nix` with this content:

```nix
{ homelab, ... }:
let
  inherit (homelab) routerVm stateVersion;
  address = routerVm.address;
  prefixLength = homelab.host.network.prefixLength;
  gateway = homelab.host.network.gateway;
  dns = homelab.host.network.dns;
in {
  networking.hostName = "router-vm";
  networking.useDHCP = false;
  networking.useNetworkd = true;
  time.timeZone = homelab.timeZone;

  systemd.network.enable = true;
  systemd.network.networks."20-lan" = {
    matchConfig.MACAddress = "02:00:00:00:40:01";
    address = [ "${address}/${toString prefixLength}" ];
    routes = [
      {
        Gateway = gateway;
      }
    ];
    dns = dns;
    networkConfig = {
      DHCP = "no";
      IPv6AcceptRA = false;
    };
  };

  users.users.root.initialPassword = "root";

  system.stateVersion = stateVersion;
}
```

- [ ] **Step 3: Re-run the existence check**

Run:

```bash
test -f modules/router-vm/identity.nix
```

Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add modules/router-vm/identity.nix
git commit -m "feat: add router-vm identity module"
```

## Task 4: Add Router VM MicroVM Wiring

**Files:**
- Create: `modules/router-vm/microvm.nix`

- [ ] **Step 1: Write the failing existence check**

Run:

```bash
test -f modules/router-vm/microvm.nix
```

Expected: FAIL because the file does not exist yet.

- [ ] **Step 2: Create the microVM module**

Create `modules/router-vm/microvm.nix` with this content:

```nix
{ homelab, ... }:
let
  inherit (homelab) routerVm;
in {
  microvm = {
    hypervisor = "qemu";
    vcpu = routerVm.vcpu;
    mem = routerVm.memory;
    interfaces = [
      {
        id = "vm-router0";
        mac = "02:00:00:00:40:01";
        type = "tap";
      }
    ];

    volumes = [
      {
        image = routerVm.stateVolume.image;
        mountPoint = routerVm.stateVolume.mountPoint;
        size = routerVm.stateVolume.size;
        fsType = routerVm.stateVolume.fsType;
        label = routerVm.stateVolume.label;
      }
    ];

    shares = [
      {
        proto = "virtiofs";
        source = routerVm.configHostPath;
        mountPoint = routerVm.configGuestPath;
        tag = "router-mihomo-config";
        securityModel = "none";
      }
    ];
  };
}
```

- [ ] **Step 3: Re-run the existence check**

Run:

```bash
test -f modules/router-vm/microvm.nix
```

Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add modules/router-vm/microvm.nix
git commit -m "feat: add router-vm microvm wiring"
```

## Task 5: Add Router VM State Directories

**Files:**
- Create: `modules/router-vm/state.nix`

- [ ] **Step 1: Write the failing existence check**

Run:

```bash
test -f modules/router-vm/state.nix
```

Expected: FAIL because the file does not exist yet.

- [ ] **Step 2: Create the state module**

Create `modules/router-vm/state.nix` with this content:

```nix
{ homelab, ... }:
let
  inherit (homelab) routerVm;
  stateRoot = routerVm.stateVolume.mountPoint;
in {
  systemd.tmpfiles.rules = [
    "d ${stateRoot} 0755 root root - -"
    "d ${stateRoot}/mihomo 0755 root root - -"
    "d ${stateRoot}/mihomo/run 0755 root root - -"
    "d ${stateRoot}/mihomo/cache 0755 root root - -"
  ];
}
```

- [ ] **Step 3: Re-run the existence check**

Run:

```bash
test -f modules/router-vm/state.nix
```

Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add modules/router-vm/state.nix
git commit -m "feat: add router-vm state directories"
```

## Task 6: Add Router VM Networking And Forwarding Primitives

**Files:**
- Create: `modules/router-vm/networking.nix`

- [ ] **Step 1: Write the failing existence check**

Run:

```bash
test -f modules/router-vm/networking.nix
```

Expected: FAIL because the file does not exist yet.

- [ ] **Step 2: Create the networking module**

Create `modules/router-vm/networking.nix` with this content:

```nix
{ ... }:
{
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv4.conf.all.rp_filter" = 0;
    "net.ipv4.conf.default.rp_filter" = 0;
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 7890 7891 9090 ];
    allowedUDPPorts = [ 53 ];
    trustedInterfaces = [ "lo" "tun0" ];
  };
}
```

- [ ] **Step 3: Re-run the existence check**

Run:

```bash
test -f modules/router-vm/networking.nix
```

Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add modules/router-vm/networking.nix
git commit -m "feat: add router-vm forwarding primitives"
```

## Task 7: Add Bootstrap-Safe Mihomo Service Wiring

**Files:**
- Create: `modules/router-vm/mihomo.nix`

- [ ] **Step 1: Write the failing existence check**

Run:

```bash
test -f modules/router-vm/mihomo.nix
```

Expected: FAIL because the file does not exist yet.

- [ ] **Step 2: Create the `mihomo` module**

Create `modules/router-vm/mihomo.nix` with this content:

```nix
{ homelab, lib, pkgs, ... }:
let
  inherit (homelab) routerVm;
  configFile = "${routerVm.configGuestPath}/config.yaml";
  stateRoot = routerVm.stateVolume.mountPoint;
in {
  services.mihomo = {
    enable = true;
    tunMode = true;
    webui = pkgs.metacubexd;
    configFile = configFile;
  };

  systemd.services.mihomo = {
    unitConfig.ConditionPathExists = lib.mkForce configFile;
    serviceConfig = {
      WorkingDirectory = "${stateRoot}/mihomo";
      StateDirectory = lib.mkForce "";
    };
  };
}
```

- [ ] **Step 3: Re-run the existence check**

Run:

```bash
test -f modules/router-vm/mihomo.nix
```

Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add modules/router-vm/mihomo.nix
git commit -m "feat: add bootstrap-safe router-vm mihomo service"
```

## Task 8: Update Flake And Docs For Router VM

**Files:**
- Modify: `flake.nix`
- Modify: `docs/operations/architecture-map.md`
- Modify: `docs/operations/services.md`
- Modify: `docs/operations/first-boot.md`
- Create: `docs/operations/router-vm.md`

- [ ] **Step 1: Write the failing doc lookup check**

Run:

```bash
rg -n "router-vm|192\\.168\\.31\\.214|/srv/data/router/mihomo|mihomo" docs/operations/architecture-map.md docs/operations/services.md docs/operations/first-boot.md docs/operations/router-vm.md
```

Expected: FAIL because the router documentation does not exist yet.

- [ ] **Step 2: Add the `router-vm` NixOS configuration output**

Update `flake.nix` so `nixosConfigurations` includes:

```nix
        router-vm = mkSystem [
          microvm.nixosModules.microvm
          ./vms/router-vm.nix
        ];
```

The full configuration list should contain `homelab`, `storage-vm`, `media-vm`, `app-vm`, and `router-vm`.

- [ ] **Step 3: Update the operations architecture map**

Append this section to `docs/operations/architecture-map.md` before `## Shared Configuration`:

```markdown
## Router VM

The router VM entrypoint is [`vms/router-vm.nix`](../../vms/router-vm.nix).

Its implementation modules live under [`modules/router-vm/`](../../modules/router-vm).

The router VM is responsible for:

- Running the LAN route-node and proxy-core workload
- Hosting `mihomo` as a dedicated network-function service
- Mounting host-local proxy config into the VM
```

- [ ] **Step 4: Update the services map**

Append this section to `docs/operations/services.md`:

```markdown
## Router Node

- Boundary: `router-vm`
- LAN address: `192.168.31.214`
- VM entrypoint: [`vms/router-vm.nix`](../../vms/router-vm.nix)
- Runtime modules: [`modules/router-vm/mihomo.nix`](../../modules/router-vm/mihomo.nix), [`modules/router-vm/networking.nix`](../../modules/router-vm/networking.nix), [`modules/router-vm/microvm.nix`](../../modules/router-vm/microvm.nix), and [`modules/router-vm/identity.nix`](../../modules/router-vm/identity.nix)
- Local config source: `/srv/data/router/mihomo`

The router VM owns route-node and ordinary proxy behavior for opted-in clients.
```

- [ ] **Step 5: Update first-boot checks**

Add these commands to the microVM and service reachability sections in `docs/operations/first-boot.md`:

```markdown
systemctl status microvm@router-vm
```

```markdown
ping -c 1 192.168.31.214
```

And add this bootstrap-safe note:

```markdown
- `router-vm` may be running even if `mihomo` is inactive because `/srv/data/router/mihomo/config.yaml` has not been created yet
```

- [ ] **Step 6: Create the dedicated router operations guide**

Create `docs/operations/router-vm.md` with this content:

```markdown
# Router VM

This document explains how to operate `router-vm`.

## Responsibilities

`router-vm` provides:

- A route-node workflow for clients that set their default gateway to `192.168.31.214`
- Ordinary `http` and `socks5` proxy entrypoints
- A dedicated `mihomo` runtime boundary

## Local Config Placement

The real `mihomo` config is stored on the host at:

- `/srv/data/router/mihomo/config.yaml`

That directory is mounted into the guest at:

- `/var/lib/router-vm/mihomo-config`

## Bootstrap Behavior

If `config.yaml` does not exist yet:

- `router-vm` should still boot
- `mihomo` should remain inactive

This is expected bootstrap state.

## Operator Workflow

1. Deploy the host and `router-vm`.
2. Confirm that `router-vm` is reachable at `192.168.31.214`.
3. Place a valid `mihomo` config at `/srv/data/router/mihomo/config.yaml`.
4. Restart `mihomo` inside `router-vm` or rebuild the host.
5. Point a test client at `192.168.31.214` either as default gateway or proxy endpoint.
```

- [ ] **Step 7: Re-run the doc lookup check**

Run:

```bash
rg -n "router-vm|192\\.168\\.31\\.214|/srv/data/router/mihomo|mihomo" docs/operations/architecture-map.md docs/operations/services.md docs/operations/first-boot.md docs/operations/router-vm.md
```

Expected: PASS with matches across all four docs.

- [ ] **Step 8: Commit**

```bash
git add flake.nix docs/operations/architecture-map.md docs/operations/services.md docs/operations/first-boot.md docs/operations/router-vm.md
git commit -m "docs: add router-vm operations guidance"
```

## Task 9: Static Verification And Build Handoff

**Files:**
- Modify: none

- [ ] **Step 1: Verify router-vm references exist**

Run:

```bash
rg -n "router-vm|routerVm|192\\.168\\.31\\.214|/srv/data/router/mihomo|/var/lib/router-vm/mihomo-config" lib flake.nix vms modules docs/operations
```

Expected: PASS with matches in shared config, flake, VM entrypoint, router modules, and operations docs.

- [ ] **Step 2: Verify the new module files exist**

Run:

```bash
test -f vms/router-vm.nix
test -f modules/router-vm/identity.nix
test -f modules/router-vm/microvm.nix
test -f modules/router-vm/networking.nix
test -f modules/router-vm/mihomo.nix
test -f modules/router-vm/state.nix
test -f docs/operations/router-vm.md
```

Expected: PASS for each file check.

- [ ] **Step 3: Run the flake evaluation checks**

Run:

```bash
nix eval .#nixosConfigurations.router-vm.config.networking.hostName
nix eval .#nixosConfigurations.homelab.config.microvm.vms.router-vm.flake.outPath
```

Expected:
- First command returns `"router-vm"`
- Second command returns a store path

- [ ] **Step 4: Build the router VM system**

Run:

```bash
nix build .#nixosConfigurations.router-vm.config.system.build.toplevel
```

Expected: PASS and produce a `result` symlink.

- [ ] **Step 5: Build the host system**

Run:

```bash
nix build .#nixosConfigurations.homelab.config.system.build.toplevel
```

Expected: PASS and produce a `result` symlink.

- [ ] **Step 6: Record the operator runtime checks**

After deployment, run:

```bash
systemctl status microvm@router-vm
ping -c 1 192.168.31.214
machinectl shell .host /usr/bin/systemctl status mihomo.service -M router-vm --no-pager
```

Expected:
- `microvm@router-vm` is active
- `192.168.31.214` responds to ping
- `mihomo.service` is inactive with a skipped condition when `/srv/data/router/mihomo/config.yaml` is absent, or active when the file exists

- [ ] **Step 7: Commit**

```bash
git add lib/homelab-config.nix flake.nix vms/router-vm.nix modules/router-vm docs/operations
git commit -m "feat: add router-vm with bootstrap-safe mihomo wiring"
```

## Self-Review

Spec coverage:
- Dedicated `router-vm` boundary: Tasks 1-4
- Fixed LAN identity `192.168.31.214`: Tasks 1 and 3
- Host-local mounted config: Tasks 1 and 4
- Bootstrap-safe missing-config behavior: Task 7 and Task 9 runtime checks
- `mihomo` route/proxy service wiring: Tasks 6-7
- Operations documentation: Task 8

Placeholder scan:
- No `TODO`, `TBD`, or deferred implementation markers remain in task steps.
- Every file creation step includes concrete code.
- Verification commands are explicit.

Type consistency:
- `routerVm.address`, `routerVm.configHostPath`, `routerVm.configGuestPath`, and `routerVm.stateVolume` are defined in Task 1 and reused consistently in later tasks.
- `router-vm` naming is consistent across `flake.nix`, the host microVM map, VM entrypoint, docs, and verification commands.
