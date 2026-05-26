switch host=`hostname -s` *args: (build host)
    nh os switch --host {{host}} --target-host {{host}} {{args}}

build host=`hostname -s`:
    nh os build --host {{host}}

repl host=`hostname -s`:
    nixos-rebuild repl --flake "$NH_FLAKE/.#{{host}}"