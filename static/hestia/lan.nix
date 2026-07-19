{
  config,
  lib,
  pkgs,
  self,
  ...
}:
let
  inherit (config.modules.pihole) interface;
  inherit (self.myLib.helpers) mkSopsFile;
in
{
  # wifi to start: the router's three ethernet ports are all spoken for. this is
  # the weak link in the design - every LAN client depends on this box for name
  # resolution, and that now rides a wireless association. wired when a port
  # frees up; nothing outside this file has to change when it does.
  sops.secrets.hestiaWifi = {
    sopsFile = mkSopsFile "privkeys/${config.networking.hostName}";
    restartUnits = [ "wpa_supplicant-${interface}.service" ];
  };

  networking = {
    # the firewall scoping and FTL's BIND listener are both keyed by interface
    # name, so the name must be stable. predictable names off gives wlan0.
    usePredictableInterfaceNames = false;

    wireless = {
      enable = true;
      interfaces = [ interface ];
      # PSK by reference, never inline: networks.*.psk lands in the
      # world-readable nix store. secretsFile is `varname=value` lines, and
      # `ext:` resolves against it at runtime.
      secretsFile = config.sops.secrets.hestiaWifi.path;
      networks."SpectrumSetup-D3".pskRaw = "ext:psk_hestia";
    };

    # every LAN client points at this box for DNS, so its address can't move.
    # a DHCP reservation on the router would work too - this way the box doesn't
    # depend on the router agreeing.
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
    # every interface, and this box will sit on untrusted networks eventually.
    # the router doesn't forward 22, so this stays inside the house.
    firewall.interfaces.${interface}.allowedTCPPorts = [ 22 ];
  };

  # wifi powersave parks the radio between packets, which on a resolver shows up
  # as multi-hundred-ms first lookups and the occasional dropped query. done with
  # `iw` rather than a driver modprobe option so it holds whatever chipset this
  # laptop turns out to have.
  systemd.services.wifi-powersave-off = {
    description = "Disable wifi power management on ${interface}";
    after = [ "sys-subsystem-net-devices-${interface}.device" ];
    bindsTo = [ "sys-subsystem-net-devices-${interface}.device" ];
    wantedBy = [ "sys-subsystem-net-devices-${interface}.device" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.iw}/bin/iw dev ${interface} set power_save off";
    };
  };

  # it's a laptop serving DNS to the house: closing the lid must not take the
  # network down with it. the battery is a free UPS, so leave power management
  # alone otherwise.
  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
  };
}
