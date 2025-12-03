# nix-configurations

My NixOS configurations, one for personal and one for server

---

## Repository Structure

```
.
├── hosts/
│   ├── ishtar/            # My main system configuration
│   └── athena/            # Linode VPS
├── hosts-common/          # Shared configuration across all hosts
├── packages/              # Custom packages (currently: ryubing-canary)
└── users/
    └── lament/            # Personal home-manager configuration
```

---

## Main inputs

### hosts/ishtar: what do I use?

- [disko](https://github.com/nix-community/disko) to handle disks
- [lanzaboote](https://github.com/nix-community/lanzaboote) (secure boot) with my own personal keys
- [sops-nix](https://github.com/Mic92/sops-nix) to handle user secrets
- [stylix](https://github.com/nix-community/stylix) for nice theming

### hosts/athena: what do I use?

- [nixos-mailserver](https://gitlab.com/simple-nixos-mailserver/nixos-mailserver) for a pre-set configured postfix+dovecot+rspamd mail stack

### users/lament:

- [nixvim](https://github.com/nix-community/nixvim) handles nvim and plugins declaratively

---

## Final notes

### Formatter preference

I prefer how alejandra looks, so that's the formatter I'm using for my personal projects. Not very important, but it's why my code looks different from official things.

### Lack of documentation

I'm just too lazy to actually document things, so don't expect much from me there

---

## License

MIT - see [LICENSE](LICENSE) for details.