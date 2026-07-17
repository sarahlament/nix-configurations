{ ... }: {
  flake.homeModules.jj =
    { pkgs, lib, ... }:
    {
      programs.jujutsu = {
        enable = true;
        settings = {
          user = {
            name = "Sarah Lament";
            email = "sarah@lament.gay";
          };
          ui.default-command = "status";

          # jj runs no git hooks, so the prek gate never fires on a jj commit.
          # `jj fix` closes the formatting half: nixfmt reads stdin, writes stdout.
          # (deadnix + statix are gated on push instead - see `just push`.)
          fix.tools.nixfmt = {
            command = [
              (lib.getExe pkgs.nixfmt)
              "-"
            ];
            patterns = [ "glob:'**/*.nix'" ];
          };
        };
      };
    };
}
