# pantheon

My personal NixOS configurations, using the [Dendritic Pattern](https://github.com/mightyiam/dendritic).

**TL;DR**

The dendritic pattern takes your flake and literally breaks it into parts. Each file is its own module, be it a `nixosModules` or `homeModules` module, or even an entire `nixosConfiguration` definition, typically via [flake-parts](https://github.com/hercules-ci/flake-parts) and [import-tree](https://github.com/denful/import-tree).

## How do I do it?

The top-level `flake.nix` uses flake-part's helper function, then pass `import-tree ./modules` to it. Everything within the `./modules` tree gets imported as a flake-parts module without the need for glue code (no `default.nix` that lists every file).

## How are modules used?

Each module is defined through `flake.{nixosModules,homeModules,etc}.moduleName`, which can then be referenced through `self.{nixosModules,homeModules,etc}.moduleName`. But a host's `activeModules` isn't one hand-written list - it's stitched together from three sources:

```nix
inherit (self.myLib.helpers) serviceModulesFor roleModulesFor;

activeModules =
  with self.nixosModules;
  [
    core        # only the genuinely host-specific bits get hand-listed
    disko
    linodeGuest
  ]
  ++ serviceModulesFor hostName # apps whose `backend` is this host
  ++ roleModulesFor hostName;   # modules pulled in by the host's `roles`
```

Everything else falls out of `directory.nix` (see below):

- `serviceModulesFor "athena"` -> every service module the directory places on `athena`, via each service's `backend`.
- `roleModulesFor "athena"` -> the modules a host's declared roles drag in (`edge.web -> caddy`, `dns.authority -> knot`, `builder -> forgejo-runner`, ...).

So adding `caddy` to a host is never a manual `activeModules` edit - it's giving that host the `edge.web` role. Per-host fine-grained toggles ride in an inner `modules = { ... }` block (the options-based half of the config):

```nix
modules = activeModules ++ [
  {
    networking.hostName = "athena";
    system.stateVersion = "26.05";

    modules = {                       # per-host option toggles
      boot.zram.enable = true;
      services.borg.subuser = "sub1";
      disko.layout = "bios-linode";
    };
  }
];
```

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
    athena.nix   ## Linode VPS - edge/ingress, WG hub, DNS, mail. serves no apps
    ishtar.nix   ## personal desktop - plasma, nvidia, gaming
    minerva.nix  ## friend-hosted spoke - the app services live here
    brigid.nix   ## VM - the `builder` (CI runner + remote builder)
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
    ${hostName}.nix
    module.nix   ## placement by colocation, diskoConfiguration handler
  lib/           ## the `myLib` layer + the directory - see above
  users/         ## see notes below
  packages.nix   ## single entrypoint for packages
static/          ## host-specific, or not modularized yet
  {hostname}/
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
Need to change how ZSH works? `homeModules`. Caddy? `nixosModules`. New host? New file in `nixosConfigurations`. As long as I know *what* I want to change, *where* it is becomes obvious.


## License

[MIT](LICENSE)