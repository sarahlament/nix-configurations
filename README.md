# LamentOS

My NixOS configurations, one for personal and one for server

---

## Repository Structure

```
.
├── hosts/
│   ├── LamentOS/          # My main system configuration
│   └── athena/            # Server setup - to be hosted on linode
├── hosts-common/          # Shared configuration across all hosts
├── packages/              # Custom packages (currently: ryubing-canary)
└── users/
    └── lament/            # Personal home-manager configuration
```

---

## LamentOS: what do I use?

- disko to handle disks
- lanzaboote (secure boot) with my own personal keys
- sops-nix to handle user secrets
- nixvim handles nvim and plugins declaratively

---

### Formatter preference

I prefer how alejandra looks, so that's the formatter I'm using for my personal projects. Not very important, but it's why my code looks different from official things.

---

## License

MIT - see [LICENSE](LICENSE) for details.