# LamentOS

My NixOS configuration and custom modules. This repo serves two purposes: providing my personal system config as a reference, and offering the **atelier** module collection for anyone to use in their own configs.

---

## Repository Structure

```
.
├── hosts/
│   ├── LamentOS/          # My main system configuration
│   └── athena/            # Server setup - to be hosted on linode
├── hosts-common/          # Shared configuration across all hosts
├── modules/               # Atelier module collection
├── packages/              # Custom packages (currently: ryubing-canary)
└── users/
    └── lament/            # Personal home-manager configuration
```

---

## Atelier: what is it?

Atelier is intended to provide a sane (and sometimes opionated) set of tools to configure your NixOS system without the hassle. It's entirely opt-in, so you only get what you want out of it.
So far it's small, but I plan on adding more as time goes on, to hopefully provide something for everyone.

Only tested on x86_64-linux, but aarch64-linux *should* work

### 'Kits'

The main focus of the atelier are the kits. They are preset configurations for different tasks, such as gaming, basic desktop environments and eventually more.

---

## LamentOS: what do I use?

- disko to handle disks
- lanzaboote (secure boot) with my own personal keys
- sops-nix to handle user secrets
- nixvim handles nvim and plugins declaratively

---
## Final notes

### Where's the docs?

For now, there are no plans for official documentation. Instead, I encourage you to look through the code itself to see what it does, as well as your preferred search engine.

### Formatter preference

I prefer how alejandra looks, so that's the formatter I'm using for my personal projects. Not very important, but it's why my code looks different from official things.

---

## License

MIT - see [LICENSE](LICENSE) for details.