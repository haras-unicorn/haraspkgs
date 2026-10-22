# Configure EditorConfig

The `editorconfig` module contributes an EditorConfig file to the shell's global
bwrap files. Treat the Nix settings as the source of truth. No `.editorconfig`
file is committed or written to the repository.

## Set the policy

```nix
{
  editorconfig = {
    enable = true;
    settings = {
      "*" = {
        charset = "utf-8";
        end_of_line = "lf";
        indent_size = 2;
        indent_style = "space";
        insert_final_newline = true;
        max_line_length = 80;
        tab_width = 2;
        trim_trailing_whitespace = true;
      };

      "*.md" = {
        max_line_length = 80;
      };
    };
  };
}
```

Each attribute under `settings` is a glob section. Section names and entry names
are written in attribute-name order. Values may be strings, integers, or
booleans; booleans are rendered as `true`/`false`.

## Change the path

```nix
{
  editorconfig.path = ".config/editorconfig";
}
```

The path is relative to the repository root. `root = true` is always emitted, so
the file is a root configuration rather than a fragment inherited from a parent
directory.

## Share it with formatters

`editorconfig.settings` remains available on the evaluated shell config. Every
wrapped tool stages the file outside the checkout and exposes it through a
read-only overlay lower layer, so tools that understand EditorConfig read the
same policy without a repository copy. Add the relevant wrapped tool to
`packages` rather than committing a configuration file.

See the [EditorConfig reference](../../reference/dev/editorconfig.md) for the
full option shape.
