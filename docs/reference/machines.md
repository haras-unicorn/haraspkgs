# Machines

Machines are declared under `self.nixosConfigurations` and
`self.homeConfigurations`. Shared modules live under `self.nixosModules` and
`self.homeModules`.

## Shape

```nix
{
  self.nixosConfigurations.workstation = {
    value =
      { ... }:
      {
        nixpkgs.system = "x86_64-linux";
        system.stateVersion = "26.05";
      };
  };

  self.nixosModules.networking = {
    value = ./modules/networking.nix;
  };

  self.homeModules.shell = {
    value = ./modules/home/shell.nix;
  };
}
```

Each entry is a submodule with `self`, `flake`, and `value`.

## Outputs

- `self.nixosConfigurations` and `self.homeConfigurations` become
  `flake.nixosConfigurations` and `flake.homeConfigurations`.
- `self.nixosModules` and `self.homeModules` become `flake.nixosModules` and
  `flake.homeModules`.
- Every NixOS configuration imports all `self.nixosModules`.
- Every Home configuration imports all `self.homeModules`.
- `networking.hostName` defaults to the configuration name.
- `home-manager.extraSpecialArgs` receives the flake's `specialArgs`.

## Notes

Each machine must set `nixpkgs.system`. `self.lib.machines` contains the
construction helpers. A downstream flake needs the `home-manager` input when
using machines.

## Related

- [Add a machine](../guides/machines.md)
- [The self namespace](../explanation/self-namespace.md)
