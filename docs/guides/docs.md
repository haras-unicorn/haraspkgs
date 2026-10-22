# Build docs

The docs helpers live in the `docs` overlay under `pkgs.harasPackages`.

## Build an mdbook site

```nix
{ pkgs, ... }:
{
  packages.docs = pkgs.harasPackages.mkMdbook {
    src = ./.;
  };
}
```

By default the book lives in `docs/` next to the source. Override `book` when
`book.toml` is somewhere else.

## Generate options documentation

```nix
{ pkgs, ... }:
{
  packages.options = (pkgs.harasPackages.mkOptionsDocs {
    modules = [ ./modules/my-module.nix ];
  }).optionsCommonMark;
}
```

Use `specialArgs` to pass extra arguments to the evaluated modules and
`transformOptions` to hide options before rendering.

## Related

- [Docs helper reference](../reference/docs.md)
