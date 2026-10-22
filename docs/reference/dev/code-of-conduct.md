# Code of conduct module

The `code-of-conduct` module is exported through
`flake.devModules.code-of-conduct` and included in the default dev module group.
It writes a Contributor Covenant file through the `file` module.

## Options

<!-- markdownlint-disable MD013 -->

| Field                                       | Type                   | Default                       | Description                                        |
| ------------------------------------------- | ---------------------- | ----------------------------- | -------------------------------------------------- |
| `codeOfConduct.contributorCovenant.enable`  | bool                   | `false`                       | Enable the generated code of conduct.              |
| `codeOfConduct.contributorCovenant.version` | string                 | `"3.0"`                       | Contributor Covenant version.                      |
| `codeOfConduct.contributorCovenant.hash`    | string                 | Contributor Covenant 3.0 hash | Fixed-output hash for the downloaded file.         |
| `codeOfConduct.contributorCovenant.source`  | path, package, or null | `null`                        | Local source file; overrides `version` and `hash`. |
| `codeOfConduct.contributorCovenant.path`    | string                 | `"CODE_OF_CONDUCT.md"`        | Path of the generated file.                        |

<!-- markdownlint-enable MD013 -->

## Behavior

When `source` is `null`, the module builds the URL from `version` by replacing
dots with slashes and fetches `code_of_conduct/code_of_conduct.md` from the
Contributor Covenant site. The fetch is a fixed-output derivation guarded by
`hash`.

The source is read at evaluation time and written through the `file` module. The
module does not add packages or CLI commands. Set `source` to a path or package
to avoid the network fetch or to use a modified file.

## Outputs

- `file.<path>.text` contains the code of conduct text.
- The self shell uses the default Contributor Covenant fetch and commits
  `CODE_OF_CONDUCT.md`.
- The file is written when the shell starts by the `file` module and formatted
  at shell entry when the `format` module is active.
- The module does not add packages or CLI commands.

## Related

- [Add a code of conduct](../../tutorials/dev/code-of-conduct.md)
- [Configure a code of conduct](../../guides/dev/code-of-conduct.md)
- [Why the module is a small file generator](../../explanation/dev/code-of-conduct.md)
- [File module](file.md)
- [devModule](../dev-module.md)
