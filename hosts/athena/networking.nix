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
  };
}
