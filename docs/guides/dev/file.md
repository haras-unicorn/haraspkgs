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

Use `file.<path>.text` to overwrite on every entry, `ensure` to leave existing
files alone, and `source` to link an immutable store copy. Text is written
first, then formatted by the matching formatter when the shell starts; set
`format = false` to keep the exact text. Source files are added to the generated
`.gitignore` by default; set `ignore = false` to keep one out.

## Enter the shell

The files are created from the bash shell hook before other hook commands. A
source file becomes a symlink to the store:

```console
$ nix develop
> linking
link .tool
> writing
write .envrc
ensure .keep
> formatting generated files
```

`file.".gitignore".text` receives the generated ignore patterns first. An
explicit `.gitignore` text definition is appended after them.
