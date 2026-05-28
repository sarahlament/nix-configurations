# we auto-import fail2ban as a 'dependency' for public-facing services, so it should never
# have to be explicitly added to the system's modules
{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.fail2ban = {
    config,
    lib,
    pkgs,
    ...
  }: {
    networking.nftables.enable = true;
    services.fail2ban = {
      enable = true;
      bantime = "1h";
      banaction = "nftables-allports";
      banaction-allports = "nftables-allports";
      bantime-increment = {
        enable = true;
        overalljails = true;
      };
      ignoreIP = [
        "192.168.0.0/16"
        "10.0.64.0/16"
      ];

      jails.DEFAULT.settings = {
        findtime = "6h";
        action = ''
          nftables-allports
            fail2ban-email
        '';
      };
      jails.recidive.settings = {
        enable = true;
        filter = "recidive";
        action = ''
          nftables-allports[name=recidivist]
            fail2ban-email
        '';
        findtime = "48h";
        bantime = "30d";
      };
    };
  };
}
