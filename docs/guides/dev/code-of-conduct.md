# Configure a code of conduct

The `code-of-conduct` module fetches the Contributor Covenant file and writes it
through the `file` module.

## Choose a version

```nix
{
  codeOfConduct.contributorCovenant = {
    enable = true;
    version = "3.0";
    hash = "sha256-7T+AiSYuoE3lnQiaJnv6CCK5PJasWmXQZH/XZ6JchCI=";
  };
}
```

`version` is converted to a URL path by replacing dots with slashes. The file is
fetched from
`https://www.contributor-covenant.org/version/<version>/code_of_conduct/code_of_conduct.md`.
Change `version` and `hash` together so the fixed-output hash matches the new
file.

## Use a local source

```nix
{
  codeOfConduct.contributorCovenant = {
    enable = true;
    source = ./CODE_OF_CONDUCT.md;
  };
}
```

When `source` is set, the module reads that file and ignores `version` and
`hash`. This is useful for a modified policy or for offline evaluation. The self
shell uses the default Contributor Covenant fetch and commits the generated
file. The `file` module formats the generated file at shell entry when the
`format` module is active.

## Change the path

```nix
{
  codeOfConduct.contributorCovenant.path = "docs/CODE_OF_CONDUCT.md";
}
```

The path is relative to the repository root.

See the [code of conduct reference](../../reference/dev/code-of-conduct.md) for
the full option shape.
