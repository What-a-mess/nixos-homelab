# RSSHub Secret Management Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add repository-managed encrypted RSSHub secrets with host-side decryption, host-to-`app-vm` runtime delivery, and bootstrap-safe conditional startup when the secret is absent.

**Architecture:** Add `agenix` at the flake and host-module level, decrypt `secrets/rsshub.env.age` on the host, expose the decrypted runtime file to `app-vm` through a dedicated `virtiofs` share, and update the RSSHub container unit to read an env file only when it exists. Keep first deployment safe by treating a missing secret as a skipped service instead of a system-wide failure.

**Tech Stack:** Nix flakes, NixOS modules, `agenix`, `microvm.nix`, Podman OCI containers, `virtiofs`, systemd

---

## File Structure

Planned file changes and responsibilities:

- Create: `secrets/secrets.nix`
  Declares encrypted secret artifacts and the host recipients used by `agenix`.
- Create: `secrets/rsshub.env.age`
  Stores the encrypted RSSHub environment file.
- Create: `modules/host/secrets.nix`
  Enables `agenix` on the host, defines the runtime secret path, and prepares a host-side directory for guest consumption.
- Modify: `flake.nix`
  Adds the `agenix` flake input and makes its NixOS module available.
- Modify: `hosts/homelab/default.nix`
  Imports the new host secret-management module.
- Modify: `lib/homelab-config.nix`
  Adds stable shared path metadata for host-side app secret export.
- Modify: `modules/app-vm/microvm.nix`
  Shares the host runtime secret directory into `app-vm` using `virtiofs`.
- Modify: `modules/app-vm/containers.nix`
  Reads the RSSHub env file from the guest-visible secret path and prevents service startup when the file is absent.
- Modify: `.gitignore`
  Excludes plaintext local secret staging files.
- Modify: `INSTALL.md`
  Documents first-boot bootstrap and secret enrollment steps.

## Task 1: Add `agenix` To The Flake And Host Entry Point

**Files:**
- Modify: `flake.nix`
- Modify: `hosts/homelab/default.nix`
- Create: `modules/host/secrets.nix`

- [ ] **Step 1: Write the failing integration check**

Add a temporary note to the plan executor that the repository should fail to evaluate until the `agenix` input and host module exist. Use this command as the first failing check:

```bash
nix build .#nixosConfigurations.homelab.config.system.build.toplevel
```

Expected: FAIL with an error that the new host secret module or `agenix` input is missing.

- [ ] **Step 2: Add the `agenix` flake input and host module wiring**

Update `flake.nix` so the inputs section and `homelab` system module list include `agenix`:

```nix
{
  description = "Declarative single-host homelab with microVM service groups";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    microvm.url = "github:microvm-nix/microvm.nix";
    microvm.inputs.nixpkgs.follows = "nixpkgs";
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nixpkgs, microvm, agenix, ... }:
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
          agenix.nixosModules.default
          ./hosts/homelab
        ];
        # existing VM definitions unchanged
      };
    };
}
```

Update `hosts/homelab/default.nix` imports:

```nix
{ homelab, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/host/boot.nix
    ../../modules/host/admin-user.nix
    ../../modules/host/ssh.nix
    ../../modules/host/power.nix
    ../../modules/host/storage.nix
    ../../modules/host/networking.nix
    ../../modules/host/microvm-host.nix
    ../../modules/host/secrets.nix
  ];
}
```

- [ ] **Step 3: Create the host secret-management module**

Create `modules/host/secrets.nix` with the host runtime path and a directory that can later be shared into `app-vm`:

```nix
{ config, homelab, pkgs, ... }:
let
  inherit (homelab) users;
  appSecretsHostPath = homelab.appVm.hostSecretsPath;
  rsshubSecret = config.age.secrets.rsshub-env.path;
in {
  age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  imports = [
    ../../secrets/secrets.nix
  ];

  systemd.tmpfiles.rules = [
    "d ${appSecretsHostPath} 0750 root root - -"
  ];

  systemd.services.export-app-vm-rsshub-secret = {
    description = "Export decrypted RSSHub env file for app-vm";
    wantedBy = [ "multi-user.target" ];
    after = [ "agenix.service" ];
    wants = [ "agenix.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      install -d -m 0750 ${appSecretsHostPath}
      if [ -f "${rsshubSecret}" ]; then
        install -m 0640 "${rsshubSecret}" "${appSecretsHostPath}/rsshub.env"
      else
        rm -f "${appSecretsHostPath}/rsshub.env"
      fi
    '';
    path = [ pkgs.coreutils pkgs.findutils ];
  };
}
```

- [ ] **Step 4: Re-run the host build**

Run:

```bash
nix build .#nixosConfigurations.homelab.config.system.build.toplevel
```

Expected: evaluation now proceeds past the former missing-input error. It may still fail because `secrets/secrets.nix` has not been added yet.

- [ ] **Step 5: Commit**

```bash
git add flake.nix hosts/homelab/default.nix modules/host/secrets.nix
git commit -m "feat: add host secret management scaffolding"
```

## Task 2: Define Encrypted Secret Artifacts And Shared Secret Paths

**Files:**
- Create: `secrets/secrets.nix`
- Create: `secrets/rsshub.env.age`
- Modify: `lib/homelab-config.nix`
- Modify: `.gitignore`

- [ ] **Step 1: Write the failing config evaluation**

Run:

```bash
nix build .#nixosConfigurations.homelab.config.system.build.toplevel
```

Expected: FAIL because `../../secrets/secrets.nix` or `config.age.secrets.rsshub-env` does not exist yet.

- [ ] **Step 2: Add stable path metadata to shared homelab config**

Update the `appVm` block in `lib/homelab-config.nix`:

```nix
  appVm = {
    memory = 2048;
    vcpu = 2;
    hostSecretsPath = "/run/app-vm-secrets";
    guestSecretsPath = "/run/host-secrets";
    stateVolume = {
      image = "/srv/data/vmstate/app-vm-state.img";
      mountPoint = "/var/lib/app-services";
      size = 8192;
      fsType = "ext4";
      label = "app-vm-state";
    };
  };
```

- [ ] **Step 3: Create the `agenix` secret declaration file**

Create `secrets/secrets.nix`:

```nix
let
  homelabHost = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAPLACEHOLDER replace-me-after-first-boot";
in {
  "rsshub.env.age".publicKeys = [ homelabHost ];
}
```

The executor must replace the placeholder with the actual host public key converted for `agenix` before relying on the secret in production.

- [ ] **Step 4: Add a placeholder encrypted artifact and local-ignore rules**

Create `secrets/rsshub.env.age` as a valid encrypted file generated from a local plaintext `.env`, not as hand-written text. For the initial commit, use a bootstrap placeholder value such as:

```dotenv
TWITTER_TOKEN=bootstrap-placeholder
```

Then encrypt it with `agenix` and save the result as `secrets/rsshub.env.age`.

Update `.gitignore` to exclude local plaintext secret staging files:

```gitignore
*.env
*.secret
secrets/*.local
```

- [ ] **Step 5: Bind the encrypted artifact into the host module**

Extend `modules/host/secrets.nix` with an explicit secret declaration:

```nix
  age.secrets.rsshub-env = {
    file = ../../secrets/rsshub.env.age;
    path = "/run/agenix/rsshub.env";
    mode = "0640";
    owner = "root";
    group = "root";
  };
```

- [ ] **Step 6: Re-run the host build**

Run:

```bash
nix build .#nixosConfigurations.homelab.config.system.build.toplevel
```

Expected: PASS for evaluation and derivation build of the host configuration.

- [ ] **Step 7: Commit**

```bash
git add lib/homelab-config.nix secrets/secrets.nix secrets/rsshub.env.age .gitignore modules/host/secrets.nix
git commit -m "feat: add encrypted RSSHub secret artifacts"
```

## Task 3: Deliver The Secret Into `app-vm` And Gate RSSHub Startup

**Files:**
- Modify: `modules/app-vm/microvm.nix`
- Modify: `modules/app-vm/containers.nix`

- [ ] **Step 1: Write the failing VM build check**

Run:

```bash
nix build .#nixosConfigurations.app-vm.config.system.build.toplevel
```

Expected: FAIL after the next test assertion is added if the container references a guest secret path that is not yet shared into the VM.

- [ ] **Step 2: Share the host runtime secret directory into `app-vm`**

Update `modules/app-vm/microvm.nix`:

```nix
{ homelab, ... }:
let
  inherit (homelab) appVm host ports;
in {
  microvm = {
    hypervisor = "qemu";
    vcpu = appVm.vcpu;
    mem = appVm.memory;
    interfaces = [
      {
        id = "app0";
        mac = "02:00:00:00:30:01";
        type = "user";
      }
    ];

    shares = [
      {
        proto = "virtiofs";
        source = appVm.hostSecretsPath;
        mountPoint = appVm.guestSecretsPath;
        tag = "app-vm-secrets";
        securityModel = "none";
      }
    ];

    volumes = [
      {
        image = appVm.stateVolume.image;
        mountPoint = appVm.stateVolume.mountPoint;
        size = appVm.stateVolume.size;
        fsType = appVm.stateVolume.fsType;
        label = appVm.stateVolume.label;
      }
    ];

    forwardPorts = [
      {
        from = "host";
        host.address = host.listenAddress;
        host.port = ports.app.rsshub;
        guest.port = ports.app.rsshub;
        proto = "tcp";
      }
    ];
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ ports.app.rsshub ];
  };
}
```

- [ ] **Step 3: Update the RSSHub container to consume the env file**

Modify `modules/app-vm/containers.nix`:

```nix
{ homelab, pkgs, ... }:
let
  inherit (homelab) appVm images ports;
  stateRoot = homelab.appVm.stateVolume.mountPoint;
  rsshubEnvFile = "${appVm.guestSecretsPath}/rsshub.env";
in {
  virtualisation.podman = {
    enable = true;
    dockerCompat = false;
    defaultNetwork.settings.dns_enabled = true;
    autoPrune.enable = true;
  };

  virtualisation.oci-containers.backend = "podman";
  virtualisation.oci-containers.containers = {
    rsshub = {
      image = images.rsshub;
      autoStart = true;
      environment = {
        NODE_ENV = "production";
        TZ = homelab.timeZone;
        PORT = toString ports.app.rsshub;
        CACHE_EXPIRE = "3600";
      };
      environmentFiles = [
        rsshubEnvFile
      ];
      volumes = [
        "${stateRoot}/rsshub:/app/.cache:rw"
        "${stateRoot}/rsshub-browser-cache:/tmp:rw"
      ];
      extraOptions = [ "--network=host" ];
    };
  };

  systemd.services.podman-rsshub = {
    unitConfig.ConditionPathExists = rsshubEnvFile;
  };

  environment.systemPackages = with pkgs; [
    podman
  ];
}
```

- [ ] **Step 4: Re-run VM and host builds**

Run:

```bash
nix build .#nixosConfigurations.app-vm.config.system.build.toplevel
nix build .#nixosConfigurations.homelab.config.system.build.toplevel
```

Expected: PASS for both builds.

- [ ] **Step 5: Add runtime verification commands**

After deployment to a real host, run:

```bash
systemctl status export-app-vm-rsshub-secret
systemctl status microvm@app-vm
systemctl status podman-rsshub.service -M app-vm
```

Expected:
- `export-app-vm-rsshub-secret` is `active (exited)`
- `microvm@app-vm` is `active`
- `podman-rsshub.service -M app-vm` is `inactive (dead)` with a skipped condition when the secret is absent, or `active` when the secret exists

- [ ] **Step 6: Commit**

```bash
git add modules/app-vm/microvm.nix modules/app-vm/containers.nix
git commit -m "feat: gate RSSHub startup on runtime secrets"
```

## Task 4: Document Bootstrap, Enrollment, And Rotation

**Files:**
- Modify: `INSTALL.md`

- [ ] **Step 1: Write the failing docs grep check**

Run:

```bash
rg -n "agenix|rsshub.env.age|ssh_host_ed25519_key.pub|app-vm-secrets" INSTALL.md
```

Expected: FAIL to find the new bootstrap instructions before they are added.

- [ ] **Step 2: Add first-boot secret bootstrap instructions**

Append an `RSSHub Secret Bootstrap` section to `INSTALL.md` with concrete commands:

```markdown
## RSSHub Secret Bootstrap

After the first successful host install, enroll the host as an `agenix` recipient and add the encrypted RSSHub environment file.

Read the host SSH public key on the installed host:

```bash
cat /etc/ssh/ssh_host_ed25519_key.pub
```

On the management machine, convert it for `agenix`, update `secrets/secrets.nix`, and create the encrypted secret:

```bash
agenix -e secrets/rsshub.env.age
```

Store environment-variable content such as:

```dotenv
TWITTER_TOKEN=replace-with-real-token
```

Rebuild after committing the encrypted file:

```bash
sudo nixos-rebuild switch --flake .#homelab
```
```

- [ ] **Step 3: Add validation notes for bootstrap-safe startup**

Extend the validation section with:

```markdown
If `RSSHub` is not configured yet, `podman-rsshub.service` inside `app-vm` may be skipped because `/run/host-secrets/rsshub.env` does not exist yet. This is expected during first boot before the encrypted secret has been enrolled.
```

- [ ] **Step 4: Re-run the docs grep**

Run:

```bash
rg -n "agenix|rsshub.env.age|ssh_host_ed25519_key.pub|app-vm-secrets" INSTALL.md
```

Expected: PASS with matches in the new bootstrap section.

- [ ] **Step 5: Commit**

```bash
git add INSTALL.md
git commit -m "docs: add RSSHub secret bootstrap workflow"
```

## Task 5: End-To-End Verification

**Files:**
- Verify only: working tree and deployed host state

- [ ] **Step 1: Build all affected systems locally**

Run:

```bash
nix build .#nixosConfigurations.homelab.config.system.build.toplevel
nix build .#nixosConfigurations.app-vm.config.system.build.toplevel
```

Expected: PASS for both builds.

- [ ] **Step 2: Deploy without a real secret to verify bootstrap behavior**

Run on the host:

```bash
sudo nixos-rebuild switch --flake .#homelab
systemctl status microvm@app-vm
systemctl status export-app-vm-rsshub-secret
machinectl shell .host /usr/bin/systemctl status podman-rsshub.service -M app-vm --no-pager
```

Expected:
- host switch succeeds
- `microvm@app-vm` is active
- export service is active
- RSSHub container service is skipped or inactive because the guest env file is absent

- [ ] **Step 3: Enroll a valid secret and verify service activation**

Run on the management machine, then redeploy:

```bash
agenix -e secrets/rsshub.env.age
git add secrets/rsshub.env.age secrets/secrets.nix
git commit -m "chore: enroll real RSSHub token"
sudo nixos-rebuild switch --flake .#homelab
```

Expected: host switch succeeds with the encrypted secret available.

- [ ] **Step 4: Verify runtime service activation and endpoint reachability**

Run on the host:

```bash
systemctl status export-app-vm-rsshub-secret
machinectl shell .host /usr/bin/systemctl status podman-rsshub.service -M app-vm --no-pager
curl -I http://127.0.0.1:1200
```

Expected:
- export service is active
- RSSHub service in `app-vm` is active
- `curl` returns an HTTP response from RSSHub

- [ ] **Step 5: Commit any final verification-only doc tweaks**

```bash
git status --short
```

Expected: clean working tree, or only intentional follow-up changes.

## Self-Review

Spec coverage:
- Repository-managed encrypted secrets: Task 2
- Host-side decryption and trust boundary: Tasks 1 and 2
- Host-to-guest runtime delivery: Task 3
- Missing-secret bootstrap behavior: Task 3 and Task 5
- First deployment and enrollment workflow: Task 4 and Task 5
- Rotation and operations: Task 4

Placeholder scan:
- The only intentional placeholder is the host recipient key in `secrets/secrets.nix`. The implementing engineer must replace it after first boot.
- Every build, deploy, and validation step includes an explicit command and expected outcome.

Type consistency:
- Shared secret paths are named `hostSecretsPath` and `guestSecretsPath` consistently across the plan.
- The secret id remains `rsshub-env` and the runtime file remains `rsshub.env` across host and guest tasks.
