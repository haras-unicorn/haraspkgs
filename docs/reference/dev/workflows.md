# Workflows module

The `workflows` module is exported through `flake.devModules.workflows` and
included in the default group. It renders GitHub Actions workflows into
`.github/workflows/<name>.yaml` when the shell starts.

## Options

<!-- markdownlint-disable MD013 -->

| Field                          | Type            | Default                  | Description                                                     |
| ------------------------------ | --------------- | ------------------------ | --------------------------------------------------------------- |
| `workflows.<name>.name`        | string          | `<name>`                 | Workflow name written to the YAML.                              |
| `workflows.<name>.installable` | string or null  | `".#<name>"`             | Installable built by the base step. `null` skips the build.     |
| `workflows.<name>.on`          | attrs           | `{}`                     | GitHub Actions triggers.                                        |
| `workflows.<name>.permissions` | attrs of string | `{}`                     | Permissions; `contents = read` is added by the renderer.        |
| `workflows.<name>.env`         | attrs           | `{}`                     | Workflow-level environment variables.                           |
| `workflows.<name>.matrix`      | attrs or null   | `null`                   | Job matrix. An `os` matrix becomes `runs-on: ${{ matrix.os }}`. |
| `workflows.<name>.runsOn`      | string          | `"ubuntu-latest"`        | Runner used without an `os` matrix.                             |
| `workflows.<name>.jobName`     | string          | `"build"`                | Name of the generated job.                                      |
| `workflows.<name>.installNix`  | bool            | `true`                   | Add the `cachix/install-nix-action` step.                       |
| `workflows.<name>.steps`       | list of attrs   | `[]`                     | Extra steps appended after the base steps.                      |
| `workflows.<name>.jobs`        | attrs           | `{}`                     | Extra jobs merged with the generated job.                       |
| `workflows.<name>.cachix`      | attrs or null   | `haras`/`haras-releases` | Cachix step configuration. `null` skips it.                     |

<!-- markdownlint-enable MD013 -->

## Behavior

The base steps are checkout, Nix, Cachix, and
`nix build --show-trace <installable>`. Extra `steps` are appended. The workflow
is rendered with `lib.generators.toYAML` and written by the `file` module, which
formats it at shell entry.

When a workflow is declared, the module also exposes a `workflows` passthru
check. It compares each committed `.github/workflows/<name>.yaml` file with the
rendered output, so `nix flake check` fails when the committed copy drifts.

## Related

- [Add a GitHub workflow](../../guides/dev/workflows.md)
- [How workflows are generated](../../explanation/dev/workflows.md)
- [devModule](../dev-module.md)
