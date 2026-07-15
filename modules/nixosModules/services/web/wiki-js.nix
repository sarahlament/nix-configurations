{ self, ... }: {
  flake.nixosModules.wiki-js =
    { config, ... }:
    let
      inherit (self.myLib.directory.hosts.${config.networking.hostName}.ip) internal;
      inherit (self.myLib.directory.services.notes) port;
    in
    {
      # tenant of the shared `postgres` role: declares its own db + role, which
      # the postgres module's backup job then picks up automatically. wiki-js
      # runs as a systemd DynamicUser named "wiki-js", and pg peer auth matches
      # on that name - so role and db must both be "wiki-js" (ensureDBOwnership
      # ties the db name to the role name).
      services.postgresql = {
        ensureDatabases = [ "wiki-js" ];
        ensureUsers = [
          {
            name = "wiki-js";
            ensureDBOwnership = true;
          }
        ];
      };

      services.wiki-js = {
        enable = true;
        settings = {
          bindIP = internal;
          inherit port;
          db = {
            type = "postgres";
            host = "/run/postgresql"; # unix socket -> peer auth, no password/secret
            port = 5432;
            user = "wiki-js";
            db = "wiki-js";
          };
        };
      };

      # our db/app split means the wiki-js unit has no built-in dependency on the
      # pg server; order it after so the ensured role + database exist before
      # wiki-js runs its migrations on first start.
      systemd.services.wiki-js = {
        after = [ "postgresql.service" ];
        requires = [ "postgresql.service" ];
      };

      # no persist entry: all wiki state lives in postgres, backed up by module 1.
    };
}
