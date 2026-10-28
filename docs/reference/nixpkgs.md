# Configure nixpkgs

`self.nixpkgs` controls the package set used by every `perSystem`. The module
imports the downstream `nixpkgs` input and sets `perSystem._module.args.pkgs`.

## Options

<!-- markdownlint-disable MD013 -->

| Option     | Type             | Default | Description                                                                    |
| ---------- | ---------------- | ------- | ------------------------------------------------------------------------------ |
| `config`   | recursive attrs  | `{}`    | Extra nixpkgs configuration; nested attrsets merge and lists are concatenated. |
| `overlays` | list of overlays | `[]`    | Extra overlays applied to the package set.                                     |

<!-- markdownlint-enable MD013 -->

## Config

`self.nixpkgs.config` is passed to nixpkgs. Two helper keys are converted into
an unfree predicate:

```nix
{
  self.nixpkgs.config = {
    cudaSupport = true;
    allowUnfree = true;
    allowUnfreePackageNames = [ "nvidia-x11" ];
    allowUnfreePredicate = [ (package: package.pname == "some-package") ];
  };
}
```

`allowUnfreePackageNames` matches by `lib.getName`. Both forms are OR-ed
together. The generated predicate is only added when at least one name or
predicate is present.

## Overlays

`self.nixpkgs.overlays` is appended after the flake's composed namespace
overlay:

```nix
{
  self.nixpkgs.overlays = [
    (final: prev: {
      my-tool = final.hello;
    })
  ];
}
```

## CUDA

Set `self.nixpkgs.config.cudaSupport = true`. The nixpkgs module then applies
the `nixos-test-driver` GPU patch used by container tests.

## Related

- [nixpkgs reference](nixpkgs.md)
- [Use CUDA](cuda.md)
