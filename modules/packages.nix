{ self, ... }: {
  perSystem =
    {
      config,
      pkgs,
      ...
    }:
    {
      packages = {
        lsfg-vk = pkgs.callPackage (self + "/static/packages/lsfg-vk.nix") { };
        forgejo-themes = pkgs.callPackage (self + "/static/packages/forgejo-themes.nix") { };
        fail2ban-email = pkgs.writeShellApplication {
          name = "fail2ban-email";
          runtimeInputs = with pkgs; [
            dnsutils
            curl
            systemd
          ];
          text = builtins.readFile (self + "/static/packages/fail2ban-email.sh");
        };
      };
      overlayAttrs = {
        inherit (config.packages) lsfg-vk fail2ban-email forgejo-themes;
      };
    };
}
