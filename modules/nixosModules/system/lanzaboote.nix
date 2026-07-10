{ inputs, self, ... }: {
  flake.nixosModules.lanzaboote =
    { config, lib, ... }:
    let
      inherit (lib) mkForce;
      inherit (self.myLib.helpers) mkSopsFile;
    in
    {
      imports = [ inputs.lanzaboote.nixosModules.lanzaboote ];

      # only the db pair signs boot files; PK/KEK/GUID stay encrypted in
      # sops/pki.yaml, decrypted by hand for the one-time enrollment.
      sops.secrets = {
        dbKey.sopsFile = mkSopsFile "pki";
        dbPem.sopsFile = mkSopsFile "pki";
      };

      boot = {
        loader = {
          systemd-boot.enable = mkForce false;
          # real ESP is at /efi (disko); without this lanzaboote defaults to /boot
          # and strands signed UKIs on the root fs. dropped by #67, restored here.
          efi.efiSysMountPoint = "/efi";
          efi.canTouchEfiVariables = true;
        };
        lanzaboote = {
          enable = true;
          privateKeyFile = config.sops.secrets.dbKey.path;
          publicKeyFile = config.sops.secrets.dbPem.path;
          configurationLimit = 3;
          settings = {
            console-mode = 0;
            timeout = 2;
          };
        };
      };
    };
}
