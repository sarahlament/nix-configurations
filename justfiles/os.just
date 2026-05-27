deploy host=`hostname -s` *args: (build host)
    nh os switch --hostname={{host}} --target-host={{host}} {{args}}

switch *args:
    nh os switch {{args}}

build host=`hostname -s` *args:
    nh os build --hostname={{host}} {{args}}

repl host=`hostname -s`:
    nixos-rebuild repl --flake "$NH_FLAKE/.#{{host}}"