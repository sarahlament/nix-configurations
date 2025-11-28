{
  config,
  lib,
  pkgs,
  ...
}: {
  programs = {
    gpg = {
      enable = true;
      mutableKeys = true;
      homedir = "/home/lament/.gnupg";
    };

    git.signing = {
      key = "ED9E24195789351E15883A327F48E306B42F5D4A";
      signByDefault = true;
    };

    #BUG: there's a bug with home-manager not properly sourcing the socket, so I do it myself
    zsh.envExtra = ''
      unset SSH_AGENT_PID
      if [[ -z "$SSH_CONNECTION" || -z "$SSH_AUTH_SOCK" ]]; then
        export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
      fi
    '';
  };

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    pinentry.package = pkgs.pinentry-tty;
    sshKeys = ["5760FCB097407ABE51DA83AB304C6B59A6F5B08A"];
  };
}
