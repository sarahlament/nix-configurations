{
  config,
  lib,
  pkgs,
  ...
}: {
  networking = {
    networkmanager.enable = false;
    usePredictableInterfaceNames = false;
    useDHCP = true;
    tempAddresses = "disabled";

    hosts = {
      "127.0.0.1" = ["headscale.lament.gay"];
    };
  };
}
