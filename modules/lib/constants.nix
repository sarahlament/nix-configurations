{
  inputs,
  lib,
  self,
  ...
}: {
  flake.myLib.constants = {
    fqdn = "lament.gay";
    addresses = {
      public.athena = {
        v4 = "104.200.16.195";
        v6 = "2600:3c00::2000:31ff:fe65:8d63";
      };
      tailnet = {
        v4 = "100.64.0.0/10";
        v6 = "fd7a:115c:a1e0::/48";
        domain = "ts";
      };
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
