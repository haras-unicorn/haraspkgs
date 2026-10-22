# How dev shells are assembled

A dev shell is assembled from one or more dev modules.

## From module to shell

1. A repository defines `self.devModules.<name>.value` as a deferred module.
2. Haraspkgs-provided modules are exported through `flake.devModules` with
   `self = false; flake = true;`; downstream modules are aggregated through
   `self.lib.devModules` with the default `self = true; flake = false;`.
3. A shell under `self.devShells.<name>.value` extends that environment.
4. For each supported system, `haraspkgs` evaluates the shell with
   `lib.evalModules`, passing `shellPkgs`, `self`, `inputs`, and `specialArgs`
   as module arguments.
5. The shell module recreates `_module.args.pkgs` from `config.nixpkgs`, then
   the shell fields from the resulting config are rendered and passed to
   `pkgs.mkShell` and emitted as `perSystem.devShells.<name>`.

Because evaluation is deferred, a dev module can use `pkgs` without hardcoding a
system.

## Mirroring and outputs

`flake.devModules` exports every haraspkgs-provided dev module, with
`default.imports` grouping them. `self.lib.devModules` contains the
downstream-owned modules. Evaluated shells appear as
`self.lib.<system>.devShells.<name>` and `perSystem.devShells.<name>`; there is
no `flake.devShells`.

## Per-module details

- [Shell module](dev/shell.md)
- [File module](dev/file.md)
- [Git module](dev/git.md)
- [Gitleaks module](dev/gitleaks.md)
- [Language registry module](dev/languages.md)
- [EditorConfig module](dev/editorconfig.md)
- [License module](dev/license.md)
- [Code of conduct module](dev/code-of-conduct.md)
- [Check module](dev/check.md)
- [Format module](dev/format.md)
- [CLI module](dev/cli.md)
- [Workflows module](dev/workflows.md)

## Repository configuration

Repository-local configuration is part of the dev shell. Modules such as `file`
and `git` generate `.gitignore` and `.gitattributes` when the shell starts,
`workflows` generates `.github/workflows/*.yaml`, and `git` builds hook scripts
into the store. The committed files exist so tools can read them before the
shell is entered; they are mirrors, not a second source of truth.

Hooks follow the same rule. The git module registers hook commands on the `dev`
CLI and installs the scripts in a store directory. Its wrapped `git` sets
`core.hooksPath` through environment configuration, so neither `.git/config` nor
`.git/hooks` is edited. It does not create one package per hook.

## Relationship to overlays

Dev shells start from the flake's package set, including the overlays declared
through `self.nixpkgs.overlays`. The shell-only overlay is added to the list,
and the shell module recreates `pkgs` from the resulting overlay list. That adds
`harasPackages.makeBubblewrapWrapper` for in-shell `bwrap` wrappers without
putting the helper into the flake's own package set. The global-bwrap overlay is
appended last, so it can inject `bwrap.files` into every wrapper. See
[shell-only overlays](overlays.md#shell-only-overlays).

## Testing

The generated `perSystem.devShells` outputs are evaluated by `nix flake check`.
Shell checks become `perSystem.checks` and are built by the same command. The
format check is one of those checks. Unit tests use the `self` API:
`self.unitTests` for system-agnostic suites and `perSystem.self.unitTests` for
per-system suites. The unit-tests module routes them to nix-unit, which adds the
`checks.<system>.nix-unit` derivation. Unit tests cover pure library helpers
only.

Dev shell behavior is covered by `self.devTests` in `tests/dev/<module>.nix`. A
test provides dev shell `modules` and a list of `commands`. The modules are
evaluated into a shell with the same default dev modules and overlay as
`self.devShells`. The test copies `self.outPath`, runs the shell's `shellHook`,
and then runs the commands in a derivation whose build phase replaces the
shell's. `self = true` tests appear in `self.lib.devTests.<system>`;
`flake = true` tests become `perSystem.checks.dev-test-<name>`. Wrappers fall
back to direct execution with cleanup when they run inside a Nix build sandbox
or on non-Linux systems, so tests that only exercise wrapper behavior can stay
`flake = true`. Use `flake = false` for tests that genuinely need a Linux
environment or a live bwrap sandbox.

Shared fixtures belong in `self.lib.test`:

```nix
self.lib.test = {
  flake = false;
  value = {
    # values used by more than one test
  };
};
```

Tests read them through `selfLib.test.value`. `flake = false` keeps the fixture
in the self mirror without exporting it as a flake output.
