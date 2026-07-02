{
  inputs,
  self,
  ...
}:
{
  flake.nixosModules.disko =
    { config, ... }:
    let
      diskoConfig = self.diskoConfigurations.${config.networking.hostName}.disko.devices;
    in
    {
      imports = [ inputs.disko.nixosModules.disko ];
      disko.devices = diskoConfig;
    };
}
