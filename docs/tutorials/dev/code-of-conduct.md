# Add a code of conduct

The `code-of-conduct` module writes a Contributor Covenant file through the
`file` module.

## Enable Contributor Covenant

```nix
{
  self.devShells.default.value = {
    codeOfConduct.contributorCovenant = {
      enable = true;
    };
  };
}
```

## Enter the shell

```console
$ nix develop
> writing
write CODE_OF_CONDUCT.md
> formatting generated files
$ sed -n '1,5p' CODE_OF_CONDUCT.md
# Contributor Covenant Code of Conduct

## Our Pledge
```

The module uses Contributor Covenant 3.0 by default. Set `version` and `hash`
together when using another version, or set `source` to a local file. Commit the
generated file, because GitHub reads it before the shell exists; the self shell
uses the default fetch.

Next, read
[how to configure the code of conduct](../../guides/dev/code-of-conduct.md) and
the [code of conduct reference](../../reference/dev/code-of-conduct.md).
