# Docs helpers

The docs overlays expose plain helper functions under the configured namespace
(`pkgs.harasPackages` by default). They are not options.

## `mkMdbook`

```nix
mkMdbook {
  name ? "docs",
  src,
  book ? "${src}/docs",
}
```

Builds an mdbook site with `pkgs.mdbook` and returns a derivation.

## `mkOptionsDocs`

```nix
mkOptionsDocs {
  name ? "options.md",
  modules,
  specialArgs ? {},
  transformOptions ? lib.id,
}
```

Evaluates `modules` with `lib.evalModules`, renders them with
`pkgs.nixosOptionsDoc`, and returns an attrset with `name` and
`optionsCommonMark`.

## Related

- [Build docs](../guides/docs.md)
