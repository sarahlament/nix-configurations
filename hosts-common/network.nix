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
      description = "tailnet is online and connected";
      after = ["network-online.target" "tailscaled.service"];
      wants = ["network-online.target" "tailscaled.service"];
    };
    services = {
      tailnet-ready = {
        description = "check for tailnet connectivity";
        after = ["tailscaled.service"];
        wants = ["tailscaled.service"];
        wantedBy = ["tailnet-online.target"];

        serviceConfig = {
          type = "oneshot";
          RemainAfterExit = true;
        };

        script = ''
          # wait for tailnet to be up
          until ${pkgs.tailscale}/bin/tailscale status --json | \
              ${pkgs.jq}/bin/jq -e '.BackendState == "Running"'; do
            sleep 2
          done

          # wait for tailnet to have an IP
          until ${pkgs.iproute2}/bin/ip addr show tailscale0 | grep -q '100\.'; do
            sleep 2
          done
        '';
      };
	    sshd = {
	      after = ["tailnet-online.target"];
  		  requires = ["tailnet-online.target"];
	  	  serviceConfig = {
          Restart = "always";
			    RestartSec = "3s";
        };
      };
    };
  };
}
