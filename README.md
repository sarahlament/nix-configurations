# nix-configurations

My personal NixOS configurations, using the [Dendritic Pattern](https://github.com/mightyiam/dendritic).

**TL;DR**

The dendritic pattern takes your flake and literally breaks it into parts. Each file is its own module, be it a `nixosModules` or `homeModules` module, or even an entire `nixosConfiguration` definition, typically via [flake-parts](https://github.com/hercules-ci/flake-parts) and [import-tree](https://github.com/denful/import-tree).

## How do I do it?

The top-level `flake.nix` uses flake-part's helper function, then pass `import-tree ./modules` to it. Everything within the `./modules` tree gets imported as a flake-parts module without the need for glue code (no `default.nix` that lists every file).

## How are modules used?

Each module is defined through `flake.{nixosModules,homeModules,etc}.moduleName`, which can then be referenced through `self.{nixosModules,homeModules,etc}.moduleName`. These modules are then imported into each `nixosConfigurations.hostName` as such:

```nix
activeModules = with self.nixosModules; [
  boot disko lanzaboote nvidia
  networking nixconf shell sops ssh
  kde gaming develop stylix workstation
  lament # yes, even my user itself is a module
];
# then, within the host or user definition
modules = activeModules ++ [
  # other things, such as {home.stateVersion = "26.05";}
];
```

## Custom lib? In flake-parts?

`flake.myLib` is a custom flake-parts option using `types.lazyAttrsOf types.raw` so that each part of the lib can be written as an individual module and merge together just like `nixosModules` or `homeModules`.

## Structure

```
modules/
  nixosConfigurations/
    athena.nix             ## Linode VPS, service host
    ishtar.nix             ## Personal desktop
  nixosModules/
    hardware/
    profiles/
    services/
    system/
  homeModules/
    apps/
    shell/
  diskoConfigurations/
    ${hostName}.nix
    module.nix              ## This is a module, but here because it handles the diskoConfigurations
  packages/
  users/
static/                     ## Sometimes, a config doesn't warrant a full module or is host-specific, so we use this for overrides
  {hostname}/
  packages/
```

Modules are organized by output type then by semantic category.

## Notes

- I use home-manager at the system level.
- No, `users` is not a valid flake output, but it made sense to keep it as a separate concern.
- For `packages`, without serious Googling I couldn't figure out how to in-line the actual package declaration, so I use `static/packages` for that.
- "You only have the two hosts, so this level of organization is overkill." Yes, yes it is.
- "You only have the two hosts, so having device specific overrides is overkill." Yes. *Yes it is.*

## So... Why?

Honestly? I liked the way the Dendritic Pattern looked on paper, and the idea of dropping a new module into the flake tree and importing it into my system instead of glue coding it (and args like `self`) in, just to forget where I put it, was enough.
Need to change how ZSH works? `homeModules`. Caddy? `nixosModules`. New host? New file in `nixosConfigurations`. As long as I know *what* I want to change, *where* it is becomes obvious.


## License

[MIT](LICENSE)