# Configure nixpkgs

`self.nixpkgs` controls the package set used by every `perSystem`. A downstream
flake only needs to provide the `nixpkgs` input; `haraspkgs` imports it.

## Config and policy

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

`allowUnfreePackageNames` and `allowUnfreePredicate` are converted into one
`allowUnfreePredicate` for nixpkgs. Other config keys are passed through.

## Add an overlay

```nix
{
  self.nixpkgs.overlays = [
    (final: prev: {
      my-tool = final.hello;
    })
  ];
}
```

The flake's composed namespace overlay is applied first, so additional overlays
can use `final.harasPackages`.

## Related

- [nixpkgs reference](../reference/nixpkgs.md)
- [Adopt haraspkgs](adoption.md)
