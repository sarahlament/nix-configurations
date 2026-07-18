{
  config,
  lib,
  ...
}:
let
  inherit (config.modules.pihole) interface;
in
{
  # every LAN client points at this box for DNS, so its address can't move.
  # a DHCP reservation on the router would work too - this way the box doesn't
  # depend on the router agreeing.
  networking = {
    # every LAN client hardcodes this box as its resolver, and the firewall +
    # FTL listener are both scoped by interface name - so the name must not
    # change if the NIC moves to a different slot. eth0 it is.
    usePredictableInterfaceNames = false;

    useDHCP = lib.mkForce false;
    interfaces.${interface}.ipv4.addresses = [
      {
        address = "192.168.1.5";
        prefixLength = 24;
      }
    ];
    defaultGateway = "192.168.1.1"; # TODO: confirm

    # SSH straight from the LAN instead of hairpinning through the hub in
    # Dallas. NOT modules.ssh.public - that sets openFirewall, which opens 22 on
    # every interface, and this box will sit on untrusted wifi eventually. the
    # router doesn't forward 22, so this stays inside the house.
    firewall.interfaces.${interface}.allowedTCPPorts = [ 22 ];
  };

  # it's a laptop serving DNS to the house: closing the lid must not take the
  # network down with it. the battery is a free UPS, so leave power management
  # alone otherwise.
  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
  };
}
