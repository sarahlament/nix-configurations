# pantheon

My personal NixOS configurations, using the [Dendritic Pattern](https://github.com/mightyiam/dendritic).

**TL;DR**

The dendritic pattern takes your flake and literally breaks it into parts. Each file is its own module, be it a `nixosModules` or `homeModules` module, or even an entire `nixosConfiguration` definition, typically via [flake-parts](https://github.com/hercules-ci/flake-parts) and [import-tree](https://github.com/denful/import-tree).

## How do I do it?

The top-level `flake.nix` uses flake-part's helper function, then pass `import-tree ./modules` to it. Everything within the `./modules` tree gets imported as a flake-parts module without the need for glue code (no `default.nix` that lists every file).

## How are modules used?

Each module is defined through `flake.{nixosModules,homeModules,etc}.moduleName`, referenced through `self.{nixosModules,homeModules,etc}.moduleName`. But no host hand-lists its modules - `mkHost` (in `nixosConfigurations/hosts.nix`) assembles every host off its `directory.nix` entry:

```nix
mkHost = name: entry:
  inputs.${entry.channel or "nixpkgs-small"}.lib.nixosSystem {
    specialArgs = { inherit inputs self; };
    modules =
      [ self.nixosModules.core ]                             # the universal base
      ++ serviceModulesFor name                              # apps whose `backend` is this host
      ++ roleModulesFor name                                 # modules its `roles` drag in
      ++ [ (inputs.import-tree (self + "/static/${name}")) ] # host-local config
      ++ [ { networking.hostName = name; system.stateVersion = entry.stateVersion; } ];
  };

# every host, generated straight from the directory - no per-host file
flake.nixosConfigurations = builtins.mapAttrs mkHost self.myLib.directory.hosts;
```

Everything falls out of `directory.nix` (see below):

- `serviceModulesFor "athena"` -> every service module the directory places on `athena`, via each service's `backend`.
- `roleModulesFor "athena"` -> the modules a host's declared roles drag in (`edge.web -> caddy`, `dns.authority -> knot`, `builder -> forgejo-runner`, ...).

So adding `caddy` to a host is never a manual edit - it's giving that host the `edge.web` role. Everything host-*local* - extra module imports (the guest/boot-trust class), per-host option toggles, the disk layout - lives in `static/<host>/host.nix`:

```nix
# static/athena/host.nix
{ self, ... }:
{
  imports = with self.nixosModules; [ linodeGuest borgbackup ];
  modules = {                       # per-host option toggles
    boot.zram.enable = true;
    services.borg.subuser = "sub1";
    disko.layout = "bios-linode";
  };
}
```

So a host is just its `directory` entry (identity, ip, keys, `stateVersion`, roles) plus its `static/<host>/` dir - `mkHost` generates the rest.

## Custom lib? In flake-parts?

`flake.myLib` is a custom flake-parts option using `types.lazyAttrsOf types.raw` so that each part of the lib can be written as an individual module and merge together just like `nixosModules` or `homeModules`.

## Okay, but where does everything actually *go*?

One file: `modules/lib/directory.nix`. It's the fleet register - every host, its keys, its WG address, and the `roles` it plays (`edge.{web,mail,vpn}`, `dns.{authority,resolver}`, `builder`, `postgres`). It also carries a flat `services` registry: each proxied app keyed by its subdomain, declaring which host is its `backend`, what `port` it serves on, and whether it's `public`.

That one file drives the boring stuff so I don't have to:

- **caddy** generates every `https://<name>.lament.gay` vhost straight from the `services` registry - no host hand-writes a `reverse_proxy`.
- **module placement** follows `backend` - a service module lands on whatever host the directory says owns it. Moving a service between machines is a one-line `backend` change.
- **kresd**, **wireguard**, and the **deploy** pipeline all read the same host/role data.

So "where does X run?" is never spelunking through modules - it's one lookup in the directory. Move a role, move a service, add a host: edit the register, everything downstream follows.

Is this overengineered? Yes. Yes it is.
Is this necessary? *Yes. Yes it is.*

## Structure

```
modules/
  nixosConfigurations/
    hosts.nix    ## the mkHost generator - builds every host from directory + static/
  nixosModules/
    hardware/    ## what devices are bolted to this box (nvidia, pipewire)
    profiles/    ## what I want this machine to feel like
    services/    ## what this host serves - grouped by concern
      edge/      ## ingress, TLS, mail
      web/       ## the proxied *.lament.gay apps
      dns/       ## authority + resolver
      data/      ## backing stores
    system/      ## the foundation every host stands on
      base/      ## boot, core, nix, secrets, the substrate (incl. guest bases)
      net/       ## the mesh and its guards (wg, ssh, fail2ban)
      builder/   ## CI runner + remote-builder wiring
      backup/    ## borg (and rsync, someday)
  homeModules/
    apps/
    shell/
  diskoConfigurations/
    <layout>.nix   ## a named disk layout (uefi-plain, uefi-luks, bios-linode, ...)
    module.nix   ## placement by colocation, diskoConfiguration handler
  lib/           ## the `myLib` layer + the directory - see above
  users/         ## see notes below
  packages.nix   ## single entrypoint for packages
static/          ## per-host config + things not modularized yet
  {hostname}/    ## host.nix (imports + toggles + disk layout) + any host-specific tweaks
  packages/      ## see note below
sops/            ## encrypted secrets, one file per category
```

Modules are organized by output type then by semantic category.

## Notes

- I use home-manager at the system level.
- No, `users` is not a valid flake output, but it made sense to keep it as a separate concern.
- For `packages`, without serious Googling I couldn't figure out how to in-line the actual package declaration, so I use `static/packages` for that.

## So... Why?

Honestly? I liked the way the Dendritic Pattern looked on paper, and the idea of dropping a new module into the flake tree and importing it into my system instead of glue coding it (and args like `self`) in, just to forget where I put it, was enough.
Need to change how ZSH works? `homeModules`. Caddy? `nixosModules`. As long as I know *what* I want to change, *where* it is becomes obvious.


## License

[MIT](LICENSE)