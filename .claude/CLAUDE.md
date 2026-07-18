# Sarah's NixOS Configuration

Multi-host NixOS config built on **flake-parts** + **import-tree**.

**Every host is impermanent** - `system/base/impermanence.nix` is unconditional, there is no longer an `impermanent` role to opt into.

- **athena** - Linode VPS. Edge/ingress (caddy), WireGuard hub, DNS authority (knot) + recursive resolver (kresd), mail. Runs no app services.
- **ishtar** - Desktop (Plasma 6, NVIDIA, lanzaboote secure boot, gaming). Declares no roles.
- **minerva** - Friend-hosted spoke (residential NAT). Hosts the app services: Forgejo/git, Grafana + Loki, wiki-js, Vaultwarden, postgres (shared tenant DB). Carries the `postgres` role.
- **brigid** - VM on a host Sarah controls, lanzaboote. Carries the `builder` role: Forgejo Actions runner + nix remote-builder.
- **hestia** - Home-LAN laptop (lanzaboote). Pi-hole + unbound for the devices that aren't WG peers; recurses from the root rather than using athena's kresd. Declares no roles.

Host roles, IPs, and keys are declared in `modules/lib/directory.nix`. Treat that as the source of truth, not this header.

---

## Architecture

### The Engine

```nix
# flake.nix - the entire output
outputs = inputs @ {flake-parts, ...}:
  flake-parts.lib.mkFlake {inherit inputs;}
  (inputs.import-tree ./modules);
```

**import-tree** recursively discovers every `.nix` file under `modules/` and feeds them to **flake-parts**, which merges their outputs. Drop a file in `modules/`, let jj snapshot it, and it's part of the flake. No manual imports.

### Two Scopes

Every file under `modules/` is a flake-parts module with two nested scopes:

```nix
# Outer: flake-parts scope - has inputs, self
{inputs, self, ...}: {
  # Inner: NixOS module scope - has config, lib, pkgs
  flake.nixosModules.example = {config, lib, pkgs, ...}: {
    # NixOS config here
  };
}
```

`inputs`/`self` live in the outer closure. `config`/`lib`/`pkgs` live in the inner function. Don't mix them up.

Files under `static/` are plain NixOS modules (not flake-parts modules). They get `inputs` and `self` via `specialArgs`.

### What goes where

| Directory | Question it answers |
|-----------|-------------------|
| `modules/nixosConfigurations/` | Which hosts exist, and what does each assemble? |
| `modules/nixosModules/system/` | What does every host need? Subgrouped: `base/` (boot, core, nix, secrets, guest bases), `net/` (wg, ssh, fail2ban), `builder/` (CI runner + remote-builder), `backup/` (borg) |
| `modules/nixosModules/hardware/` | What is this machine? |
| `modules/nixosModules/services/` | What does this machine serve? Subgrouped: `edge/` (ingress, TLS, mail), `web/` (the proxied `*.lament.gay` apps), `dns/` (authority + resolver), `data/` (backing stores) |
| `modules/nixosModules/profiles/` | What do I want this machine to be like? |
| `modules/homeModules/shell/` | What's part of my shell experience? |
| `modules/homeModules/apps/` | What standalone applications do I launch? |
| `modules/users/` | User definitions |
| `modules/lib/` | The `myLib` layer (see below) |
| `modules/packages.nix` | Custom package wiring + overlay |
| `modules/deploy.nix` | Fleet deploy pipeline (reads the directory) |
| `modules/top-level.nix` | Flake-level option declarations (incl. `myLib`) |
| `static/{hostname}/` | What's too host-specific for a module? |
| `static/packages/` | Package derivation sources |
| `sops/` | Encrypted secrets - see the Secrets convention |

Top-level grouping is by **flake output type**, then by **semantic category**. Exception: `diskoConfigurations/module.nix` is a nixosModule that lives with the disko configs it serves (colocation by concern).

---

## The myLib layer

`modules/lib/` populates `flake.myLib`, the single source of truth for cross-cutting facts. Reference it from modules instead of hardcoding, and if a fact lives here, don't restate it elsewhere (that's what rots this doc).

- **`constants`** (`lib/constants.nix`) - `fqdn` (`lament.gay`), `addresses.internal` (WG ULA prefix), HE secondary/notify nameserver IPs, borg creds.
- **`helpers`** (`lib/helpers.nix`) - `mkReverseProxy { host ? "localhost", port, bindTo ? null }` (emits a caddy `reverse_proxy`; sets `bind` for VPN-only vhosts, auto-brackets a v6 host), `serviceModulesFor hostName` (the modules a host runs, derived from the directory), `roleModulesFor hostName` (modules pulled in by the host's declared `roles`, keyed by role *path* so nested groups like `edge.web` work), `roleHost path` (finds the host declaring a role, e.g. `roleHost [ "edge" "mail" ]`), `mkBorgRepo subuser`, `mkSopsFile name` (resolves to `sops/<name>.yaml`).
- **`directory`** (`lib/directory.nix`) - the fleet: `hosts` (athena/ishtar/minerva/brigid) and `peers` (phone/tablet, WG clients not full hosts) with their `keys`, `ip.internal`, `roles` (nested groups `edge.{vpn,web,mail}` and `dns.{authority,resolver}`, plus flat `builder` and `postgres`); plus `services`, a flat registry keyed by subdomain where each entry declares its `backend` host, `port`, `module`, whether it's `public`, and optional caddy `extraConfig`. This registry drives caddy, kresd, and module placement.

`myLib` is declared as a flake option in `top-level.nix`, so any file can extend it.

---

## Module Patterns

### Standalone (import = enable)

Most modules. A host opts in by listing it in its `activeModules`. No enable flag needed.

### Directory-driven (services)

Proxied web services aren't hand-listed. Each host's nixosConfiguration derives a `serviceModules` list (sibling to `activeModules`) via `serviceModulesFor "<host>"`: a service module is placed on whatever host its `directory.services` entry names as `backend`, and caddy generates its vhost on the edge. Moving a service between hosts is a one-line `backend` change.

### Options-based (fine-grained control)

When a module needs per-host toggles. Options live under `modules.<name>.*`:

```nix
modules.boot.desktop.enable = true;
modules.boot.zswap.enable = true;
modules.lament.desktop.enable = true;
modules.ssh.public = true;
```

### Multiple output types in one file

flake-parts merges, so a single file can define both `flake.nixosModules.foo` and `flake.homeModules.foo` when those concerns are tightly coupled (e.g. `develop.nix`).

---

## Conventions

Each entry follows **Is** / **Lives** / **Gotcha** (Gotcha optional). Copy the shape when adding one.

### Domains & Caddy
**Is:** one ingress/edge host (wherever `caddy` is imported) terminates TLS on 80/443 and serves every service at `https://<name>.lament.gay`, generating the vhosts itself from `myLib.directory.services`. Each proxies to `localhost` when the service's `backend` is the edge, else to the backend's WG internal IP `[fd..]:port`; non-`public` services also `bind` the edge's WG internal address, so they're VPN-only.
**Lives:** the generator in `services/edge/caddy.nix`, built from the registry via `mkReverseProxy` (`myLib.helpers`). Service modules carry **no** caddy config - adding or moving a vhost is a `directory.services` edit, never an inline `services.caddy.virtualHosts`.

### Networking
**Is:** plain WireGuard hub-spoke on the `internal` interface. The `edge.vpn` host coordinates; spokes peer only to the hub. Peers, keys, and IPs come from the directory.
**Lives:** `system/net/networking.nix`, driven by `myLib.directory` roles.
**Gotcha:** `internal` is the trusted firewall interface. The hub sets global `net.ipv6.conf.all.forwarding` so spoke-to-spoke traffic (e.g. phone -> ishtar) hairpins through it.

### Secrets
**Is:** sops-nix + age, scoped per host. One admin key (`lament`) can decrypt everything for local editing; each host has its own key and decrypts only what it needs. Every host reads its own key from `/persist/key.age`.
**Lives:** `.sops.yaml` is the source of truth for which key opens which file - it's commented per rule, read it rather than restating the mapping here. Files sit under `sops/`, flat for fleet-wide categories (`domain`, `mail`, `pass`, `services`) and nested where a secret is per-host or per-instance (`privkeys/<host>`, `borg/<subuser>`, `pki/{db,lament}`). Reference them via `mkSopsFile "<path>"`; declare secrets inline in the consuming module (`sops.secrets.name = {...}`).
**Gotcha:** `mkSopsFile` takes a *path*, not a flat category - the nested cases pass a slash and interpolate: `mkSopsFile "privkeys/${config.networking.hostName}"`, `mkSopsFile "borg/${cfg.subuser}"`, `mkSopsFile "pki/db"`. Adding a new file means adding a matching `creation_rule` in `.sops.yaml`, or it encrypts to the wrong key set.

### Disko auto-wiring
**Is:** each host picks its disk layout by hostname automatically.
**Lives:** `diskoConfigurations/module.nix`; hosts just include `disko` in `activeModules`.

### Home-Manager
**Is:** integrated as a NixOS module (not standalone), so `useGlobalPkgs`/`useUserPackages` work.
**Lives:** base config + shared shell modules in `core.nix` (`home-manager.sharedModules`); `users/lament.nix` is the bridge that defines the NixOS user, imports HM, and composes the user/desktop modules.

### Custom packages
**Is:** derivations exposed fleet-wide as `pkgs.<name>` via an overlay.
**Lives:** wiring in `modules/packages.nix` (`perSystem` + easyOverlay `overlayAttrs`), sources in `static/packages/`. The overlay is applied once in `system/base/nixconf.nix`, so every host inherits it through `core`.

---

## Adding Things

- **NixOS module:** Create in `modules/nixosModules/{category}/`, define `flake.nixosModules.name`, add to host's `activeModules`
- **Service:** Create the module in `services/` (no caddy config; read its own port from `directory.services.<name>.port`). Add the entry to `directory.services` (`backend`/`port`/`module`/`public?`/`extraConfig?`) - that places the module on its backend and generates its vhost on the edge
- **Home-manager module:** Create in `modules/homeModules/{shell,apps}/`, define `flake.homeModules.name`, add to `sharedModules` in `core.nix` (shared) or `users/lament.nix` (user/desktop)
- **Host:** Run `just newhost <name>` first - it mints the ssh/wg keys into `sops/privkeys/<name>.yaml` and prints the pubkeys + `.sops.yaml` blocks to paste (keys are minted *locally*, never on the box: `sshd.nix` sets `generateHostKeys = false`). Then create the nixosConfiguration in `modules/nixosConfigurations/` (deriving `serviceModules` via `serviceModulesFor "<host>"`), add a disk layout in `diskoConfigurations/`, add the entry to `lib/directory.nix`, optionally add `static/{hostname}/`, and `sops updatekeys sops/pass.yaml` so the host can decrypt the fleet-wide secrets
- **Host-specific tweak:** Drop a `.nix` file in `static/{hostname}/`. Auto-imported, no registration needed
- **Custom package:** Source in `static/packages/`, wiring in `modules/packages.nix` with `perSystem` + `overlayAttrs`
- **Secret:** Add to the right `sops/<category>.yaml`, reference via `mkSopsFile`

---

## Nix style

Idioms to respect when editing (don't "clean these up"):

- **Keep unused function args.** `lib`/`pkgs`/`config` left in a module's signature are intentional (consistency, ready-to-use). Don't strip them even when the IDE flags them unused.
- **Prefer `inherit`.** When a binding points at a nested attr, keep the `inherit (x.nested) name;` form and update references - don't rewrite to a plain `name = x.nested.name;`. Exception: `.path` pointers (e.g. `config.sops.secrets.foo.path`) stay plain bindings - they *point to*, not *consume*.

---

## Gotchas

- **import-tree only sees tracked files.** jj auto-snapshots on any command, so run a `jj st` (or any jj command) after writing a brand-new file to flush it into the tree before evaluating - never `git add` in this colocated repo, it desyncs git's index from jj's snapshot.
- **`static/` files are NixOS modules, not flake-parts modules.** They get `inputs`/`self` from `specialArgs`, not outer function args.
- **Guest modules override system defaults via priority.** `system/base/virtualGuest.nix` pins the stable kernel (`pkgs.linuxPackages`) without `mkDefault`, so it beats `boot.nix`'s `mkDefault pkgs.linuxPackages_zen`. This is intentional, and it applies to every virtual guest - `linodeGuest.nix` inherits it by importing `virtualGuest`, so athena and brigid both land on stable while ishtar keeps zen.
- **Module names can differ from filenames.** `sshd.nix` defines `flake.nixosModules.ssh` (not `sshd`). Reference the module name in `activeModules`, not the file.
