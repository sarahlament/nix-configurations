alias help := default

[private]
default:
    @just --list --list-submodules

mod flake 'justfiles/flake.just'
mod os 'justfiles/os.just'

push:
    git push --force-with-lease

rebase diff="":
    git rebase -i {{ if diff == "" { "origin/main" } else { "HEAD~" + diff } }}
