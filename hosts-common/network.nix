{
  config,
  lib,
  pkgs,
  ...
}: {
  networking.networkmanager.enable = lib.mkDefault true;
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "client";
    extraUpFlags = [
      "--login-server https://headscale.lament.gay"
    ];
  };

  services.openssh = {
    enable = true;
		settings = {
		  PasswordAuthentication = false;
			KbdInteractiveAuthentication = false;
			PermitRootLogin = false;
    };
  };

	systemd = {
	  targets.tailnet-online = {
		  description = "tailnet is connected";
			after = ["network-online.target" "tailscaled.service"];
			wants = ["network-online.target" "tailscaled.service"];
    };
	  services.sshd = {
	    after = ["tailnet-online.target"];
		  requires = ["tailnet-online.target"];
		  serviceConfig = {
        Restart = "always";
			  RestartSec = "3s";
      };
    };'
  };
}
