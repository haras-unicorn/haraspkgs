# Add a dev shell

A dev module describes what a development shell needs. Downstream
`self.devModules` holds reusable modules, haraspkgs-provided modules are
exported through `flake.devModules`, and `self.devShells` selects and extends
them. All are deferred: `pkgs` is available only when a system is evaluated.

This page is the overview. The individual modules have their own guides:

- [Use the shell module](dev/shell.md)
- [Generate files](dev/file.md)
- [Configure git](dev/git.md)
- [Scan for secrets](dev/gitleaks.md)
- [Configure languages](dev/languages.md)
- [Configure EditorConfig](dev/editorconfig.md)
- [Generate a license](dev/license.md)
- [Configure a code of conduct](dev/code-of-conduct.md)
- [Configure checks](dev/check.md)
- [Configure formatting](dev/format.md)
- [Add a dev command](dev/cli.md)
- [Generate GitHub workflows](dev/workflows.md)

## Module ownership

A downstream module keeps the defaults `self = true; flake = false;`, so it is
available to every shell but is not exported as a flake output. Haraspkgs' own
dev modules use `self = false; flake = true;` and are exported through
`flake.devModules`. Exported and downstream module lists are disjoint, so a
module is never imported twice.

## Outputs

- Each shell is exposed as `perSystem.devShells.<name>`.
- `self.lib.<system>.devShells.<name>` contains the evaluated shell.
- `flake.devModules` exports every haraspkgs-provided dev module.
- `self.lib.devModules` contains the downstream-owned dev modules.
- Shell checks become `perSystem.checks`, and the `default` shell's formatter
  becomes `perSystem.formatter`.

Dev modules receive the flake-parts context (`self`, `inputs`, `specialArgs`)
and `shellPkgs`. The shell recreates `_module.args.pkgs` from
`config.nixpkgs.system`, `config.nixpkgs.config`, and the merged overlay list,
so `pkgs` includes the flake overlays and any shell-local `nixpkgs.overlays`.
Checks use `self.outPath` when they need a copy of the repository.

Every shell includes the shared `dev` CLI. Add repository-specific subcommands
under `cli.commands`; `dev check`, `dev format`, and `dev hook-<name>` are wired
automatically by the `check`, `format`, and `git` modules.

Evaluated shells also receive the shell overlay, so
`pkgs.harasPackages.makeBubblewrapWrapper` is available when a dev module needs
to run a tool through `bwrap` with controlled files, environment, and arguments.
Files declared under `bwrap.files` are delivered to every wrapper. See
[wrap a tool with bwrap](overlays.md#wrap-a-tool-with-bwrap).

Repository-local configuration should live in dev modules. Use `file`, `git`,
and `workflows` to generate `.gitignore`, `.gitattributes`, hooks,
`.github/workflows/*.yaml`, and similar files. A committed copy is only a mirror
for tools that run before the shell starts; the dev module is the source of
truth.
