# Generate EditorConfig

The `editorconfig` module renders `.editorconfig` from structured settings. The
file is delivered to wrapped tools through bwrap and is not stored in the
repository.

## Enable the module

```nix
{
  self.devShells.default.value = {
    editorconfig = {
      enable = true;
      settings."*" = {
        charset = "utf-8";
        end_of_line = "lf";
        indent_style = "space";
        indent_size = 2;
        insert_final_newline = true;
        trim_trailing_whitespace = true;
      };
    };
  };
}
```

## Use a wrapped reader

```console
$ nix develop
$ cat .editorconfig
cat: .editorconfig: No such file or directory
$ read-editorconfig
root = true

[*]
charset = utf-8
end_of_line = lf
indent_size = 2
indent_style = space
insert_final_newline = true
```

`read-editorconfig` is a `makeBubblewrapWrapper` command in the tutorial
exercise. The file appears only while it runs. Sections are written in
attribute-name order, and `root = true` is always the first line. Booleans
render as `true` or `false`; numbers render as decimal strings.

Next, read [how to configure EditorConfig](../../guides/dev/editorconfig.md) and
the [EditorConfig reference](../../reference/dev/editorconfig.md).
