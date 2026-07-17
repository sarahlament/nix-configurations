{ config, ... }:
{
  # daily backup of the config work-tree, including uncommitted work
  services.borgbackup.jobs.${config.networking.hostName}.paths = [
    "/home/lament/Projects/pantheon"
  ];
}
