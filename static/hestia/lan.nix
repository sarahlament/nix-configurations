{
  config,
  lib,
  pkgs,
  self,
  ...
}:
let
  # the wireless interface this box's networking is keyed to. was borrowed from
  # the pihole module while it lived here; it's a networking fact, not a pihole
  # one, so it stays put now that the service is gone.
  interface = "wlan0";
  inherit (self.myLib.helpers) mkSopsFile;
in
{
  # wifi to start: the router's three ethernet ports are all spoken for. this is
  # the weak link in the design - every LAN client depends on this box for name
  # resolution, and that now rides a wireless association. wired when a port
  # frees up; nothing outside this file has to change when it does.
  # wpa_supplicant's unit is hardened and runs as its own user, not root, so a
  # default 0400 root-owned secret is unreadable to it - the association fails
  # with "EXT PW FILE: Permission denied" and no PSK. nixpkgs already binds this
  # path into the unit's sandbox; only the ownership needs to agree.
  sops.secrets.hestiaWifi = {
    sopsFile = mkSopsFile "privkeys/${config.networking.hostName}";
    owner = config.systemd.services."wpa_supplicant-${interface}".serviceConfig.User;
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
    #
    # scoped to the wireless interface rather than set host-wide: ethernet keeps
    # its DHCP default, so plugging a cable in always yields a reachable box.
    # that's the rescue path - wifi is the only link this host normally has, and
    # without it a bad wireless state means a console session or a reinstall
    # instead of an ssh session.
    interfaces.${interface} = {
      useDHCP = lib.mkForce false;
      ipv4.addresses = [
        {
          address = "192.168.1.5";
          prefixLength = 24;
        }
      ];
    };
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
