{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.niri = {
    config,
    lib,
    pkgs,
    ...
  }: {
    programs.niri = {
      enable = true;
      settings = {
      };
    };
    services.greetd = {
      enable = true;
      settings.default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --cmd niri_session";
        user = "greetd";
      };
    };
  };
}
