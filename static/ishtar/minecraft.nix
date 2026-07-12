{ inputs, pkgs, ... }:
let
  # ishtar's LAN address; the server binds here so it's reachable on the local
  # net but NOT over the WireGuard `internal` iface (trusted fleet-wide, so a
  # 0.0.0.0 bind would leak it to phone/tablet peers). pin this via a DHCP
  # reservation so it doesn't wander.
  lanAddr = "192.168.1.77";
  lanIface = "enp8s0";
in
{
  imports = [ inputs.nix-minecraft.nixosModules.minecraft-servers ];
  nixpkgs.overlays = [ inputs.nix-minecraft.overlays.default ];

  # LAN-only ingress. openFirewall would open on every iface (incl. WG);
  # scope to the LAN iface and let server-ip keep it off `internal`.
  networking.firewall.interfaces.${lanIface}.allowedTCPPorts = [ 25565 ];

  services.minecraft-servers = {
    enable = true;
    eula = true;
    openFirewall = false;
    dataDir = "/srv/minecraft";

    servers.atm10-tts = {
      enable = true;
      autoStart = false; # desktop: start on demand, don't eat 12G every boot

      # pinned to the exact NeoForge build ATM10-TTS ships (1.21.1, 21.1.221).
      package = pkgs.neoforgeServers.neoforge-1_21_1-21_1_221;

      # ~12G heap (pack floor is 10G); you game on this box too, so tune down
      # if it starves your session. usual Aikar G1GC flags.
      jvmOpts = "-Xms10G -Xmx12G -XX:+UseG1GC -XX:+UnlockExperimentalVMOptions -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:MaxGCPauseMillis=50";

      serverProperties = {
        server-ip = lanAddr; # the "not internal" enforcement
        server-port = 25565;
        motd = "ATM10 To The Sky";
        white-list = true;
        max-players = 10;
        difficulty = "normal";
        allow-flight = true; # modded flight, else players get kicked
        view-distance = 10;
      };

      whitelist = {
        SarahLament = "3f99b647-2bda-4d35-a3fa-46d610032193";
        CastaliaFae = "11a61f67-f51f-4dc6-802d-cbdb8b4ba00d";
      };
    };
  };
}
