# The git module

The `git` module is a policy layer over the `file`, `cli`, and shell-overlay
modules. It writes ignore patterns and attributes through `file`, registers hook
commands on the `dev` CLI, and wraps `git` so hooks are active without changing
the repository's Git configuration.

## Repository configuration belongs in the shell

Ignore patterns, attributes, and hooks are repository configuration, so they are
expressed in Nix and written when the shell starts. The committed files are
mirrors of the configuration, not a second source of truth. The broader goal is
to move repository-local configuration into dev modules wherever the tool can
consume the generated file. This repository's default shell already enables the
module and selects the `Nix` template.

## Gitignore templates are an input

`github-gitignore` is a non-flake input pointing at `github/gitignore`. Template
entries name files in that repository, so updating the input is the only update
step. The module reads the template at evaluation time and adds a provenance
comment to the generated `.gitignore`.

Keeping this as an input avoids vendored copies and per-template hashes.

## Hooks are CLI subcommands

A hook is registered as `cli.commands.hook-<name>`. Its script execs the
installed `dev` CLI with that subcommand. There is no `dev-git-hook-*` package
per hook; the CLI is the one executable for all hook, check, format, and
repository commands.

The hook scripts live in a generated store directory. The module replaces `git`
with a `bwrap` wrapper that sets `core.hooksPath` through the
`GIT_CONFIG_COUNT`/`GIT_CONFIG_KEY_0`/`GIT_CONFIG_VALUE_0` environment
variables. Git honors those variables for the process, so no `.git/config` write
is needed, and Git's own child processes see the same hook path. The wrapper
also mounts the project root read-write so Git and its hooks can update the
checkout.

## The gitignore seam

The `file` module already writes `.gitignore` for linked files. The git module
adds its patterns and templates as plain `.gitignore` text; the `file` module
prepends generated ignore patterns. None of these steps read the generated
`.gitignore` back, which keeps the option evaluation acyclic.

## Related

- [Configure git](../../guides/dev/git.md)
- [Git module reference](../../reference/dev/git.md)
- [The file module](file.md)
- [The CLI module](cli.md)
