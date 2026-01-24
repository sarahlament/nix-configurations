{
  config,
  lib,
  pkgs,
  ...
} : {
  networking.hosts = {
    "0.0.0.0" = [
      "data-p.gryphline.com"
       "native-log-collect.gryphline.com"
       "eventlog.gryphline.com"
       "event-log-api-ipv6.gryphline.com"
       "event-log-api-data-platform-data-lake-prod.gryphline.com" 
    ];
  };
}