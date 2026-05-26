alias help := default

[private]
default:
    @just --list --list-submodules

mod flake 'justfiles/flake.just'
mod os 'justfiles/os.just'
