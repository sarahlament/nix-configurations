inputs: {
  imports = [
    # Let's import both home-manager and stylix directly as a part of my 'it-just-works' config.
    # This allows 'home-manager.*' and 'stylix.*' options to be used globally, even outside atelier
    inputs.home-manager.nixosModules.home-manager
    inputs.stylix.nixosModules.stylix
    ./system # core system identity
    ./user # core user identies
    ./hardware # hardware settings
    ./shell # shell related settings
    ./kits # composable system kits
  ];
}
