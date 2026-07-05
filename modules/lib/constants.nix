{ ... }: {
  flake.myLib.constants = {
    fqdn = "lament.gay";
    wgPort = 51820;
    addresses = {
      internal = "fd67:d6a7:d6f3::/48";
      nameserver = {
        secondary = {
          v4 = "216.218.133.2";
          v6 = "2001:470:600::2";
        };
        notify = {
          v4 = "216.218.130.2";
          v6 = "2001:470:100::2";
        };
      };
    };
    borg = {
      user = "u612198";
      host = "your-storagebox.de:23";
    };
  };
}
