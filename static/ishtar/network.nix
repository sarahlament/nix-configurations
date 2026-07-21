{ ... }: {
  networking = {
    hosts = {
      "0.0.0.0" = [
        "data-p.gryphline.com"
        "native-log-collect.gryphline.com"
        "eventlog.gryphline.com"
        "event-log-api-ipv6.gryphline.com"
        "event-log-api-data-platform-data-lake-prod.gryphline.com"
      ];
    };

    # static LAN v4 so the router can reserve + port-forward to a fixed address.
    # pinned INSIDE dhcpcd (not `interfaces.enp8s0.useDHCP = false`) so dhcpcd
    # keeps managing IPv6 (SLAAC/RA) on the interface - that's intentional here.
    dhcpcd.extraConfig = ''
      interface enp8s0
      static ip_address=192.168.1.15/24
      static routers=192.168.1.1
    '';
  };
}
