{
  inputs,
  lib,
  self,
  ...
}: {
  flake.myLib.constants = {
    fqdn = "lament.gay";
    addresses.tailnet = {
      v4 = "100.64.0.0/10";
      v6 = "fd7a:115c:a1e0::/48";
      domain = "ts";
    };
    borg = {
      user = "u612198";
      host = "your-storagebox.de:23";
    };
  };
}
