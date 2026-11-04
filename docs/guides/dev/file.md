# Generate files

The `file` module writes or links repository files when a shell starts. It is
exported as `flake.devModules.file` and included in the default group.

## Define files

```nix
{
  self.devShells.example = {
    value = {
      file.".envrc".text = "use flake";
      file.".keep".ensure = "created once";
      file.".tool".source = ./tool.sh;
      file.".tool".executable = true;
    };
  };
}
```

Use `file.<path>.text` to keep a file in sync on every entry, `ensure` to leave
existing files alone, and `source` to link an immutable store copy. Text is
formatted in memory by the matching formatter and written only when it differs
from the file on disk; set `format = false` to keep the exact text. Source files
are added to the generated `.gitignore` by default; set `ignore = false` to keep
one out.

## Merge into a hand-written file

Some files, like `Cargo.toml`, are written by hand but should also receive
shared configuration. Set `partial` to merge `text` or `source` into the file
instead of replacing it:

```nix
{
  file."Cargo.toml" = {
    text = ''
      [workspace.lints.clippy]
      unwrap_used = "deny"
    '';
    partial.toml = true;
  };
}
```

The tag picks the format: `text`, `json`, `toml` or `yaml`. `text` appends the
text when the file does not contain it. The other three merge the declared
values into the file with [yq](https://github.com/mikefarah/yq), and your
declared values win. Because yq does the merge, its rules decide what happens to
comments, key order and arrays; see its documentation for the details.

## Check generated files

When the `check` module is present, it gets a `file` check. It fails when a
`text` file differs from its formatted text, when an `ensure` file is missing,
or when a `partial` file is not identical to its merged and formatted result. So
`dev check` and `nix flake check` catch committed files that drifted from what
the shell would generate. Files with `ignore = true`, such as linked `source`
files, are not checked.

## Enter the shell

The files are created from the bash shell hook before other hook commands. A
source file becomes a symlink to the store. The hook reports only what it
changed, so a second entry prints nothing under each heading:

```console
$ nix develop
> linking
link .tool
> writing
write .envrc
write .keep
```

`file.".gitignore".text` receives the generated ignore patterns first. An
explicit `.gitignore` text definition is appended after them.
