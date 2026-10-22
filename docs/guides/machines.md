# Add a machine

A machine is a NixOS module stored under `self.nixosConfigurations`.

## Define a machine

```nix
{ self, ... }:
{
  self.nixosConfigurations.workstation = {
    value =
      { ... }:
      {
        nixpkgs.system = "x86_64-linux";
        system.stateVersion = "26.05";
      };
  };
}
```

Each machine must set `nixpkgs.system`. The result is exposed as
`flake.nixosConfigurations.workstation`.

## Shared modules

Use `self.nixosModules` for NixOS modules imported by every machine, and
`self.homeModules` for Home Manager modules shared by every Home configuration:

```nix
{
  self.nixosModules.networking.value = ./modules/networking.nix;
  self.homeModules.shell.value = ./modules/home/shell.nix;
}
```

Every `nixosModules` entry is added to every machine. Every `homeModules` entry
is added to `home-manager.sharedModules`. The flake's `specialArgs` is passed to
`lib.nixosSystem` and to `home-manager.extraSpecialArgs`.

## Inputs

Machines use the `home-manager` input:

```nix
{
  inputs.home-manager.url = "github:nix-community/home-manager/release-26.05";
  inputs.home-manager.inputs.nixpkgs.follows = "nixpkgs";
}
```

## Verify

```console
nix flake check
```

See the [machines reference](../reference/machines.md) for the option shapes.
