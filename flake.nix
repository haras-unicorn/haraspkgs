{
  description = "Common Nix library and packages I use across my repositories.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    import-tree.url = "github:vic/import-tree";

    github-gitignore = {
      url = "github:github/gitignore";
      flake = false;
    };

    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-unit.url = "github:nix-community/nix-unit";
    nix-unit.inputs.nixpkgs.follows = "nixpkgs";

    bun2nix.url = "github:nix-community/bun2nix/0f2a1f0b6f42cebe3b149bf62d38754c5e0e9729";
    bun2nix.inputs.nixpkgs.follows = "nixpkgs";
    bun2nix.inputs.flake-parts.follows = "flake-parts";

    pyproject-nix.url = "github:pyproject-nix/pyproject.nix";
    pyproject-nix.inputs.nixpkgs.follows = "nixpkgs";

    uv2nix.url = "github:pyproject-nix/uv2nix";
    uv2nix.inputs.pyproject-nix.follows = "pyproject-nix";
    uv2nix.inputs.nixpkgs.follows = "nixpkgs";

    pyproject-build-systems.url = "github:pyproject-nix/build-system-pkgs";
    pyproject-build-systems.inputs.pyproject-nix.follows = "pyproject-nix";
    pyproject-build-systems.inputs.uv2nix.follows = "uv2nix";
    pyproject-build-systems.inputs.nixpkgs.follows = "nixpkgs";

    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";

    crane.url = "github:ipetkov/crane";
  };

  outputs =
    {
      flake-parts,
      import-tree,
      ...
    }@inputs:
    let
      bootstrapped =
        flake-parts.lib.mkFlake
          {
            inherit inputs;
            specialArgs = {
              __haraspkgsSelfFreeformType = true;
            };
          }
          {
            imports = (import-tree.addPath ./src).files ++ (import-tree.addPath ./tests).files;
          };
    in
    bootstrapped.lib.makeFlake {
      inherit inputs;
      modules = [
        ./src
        ./tests
      ];
    };

  nixConfig = {
    extra-substituters = [
      "https://haras.cachix.org"
      "https://haras-releases.cachix.org"
    ];
    extra-trusted-public-keys = [
      # cspell:disable
      "haras.cachix.org-1:/HIo1JYqOIH1Nwk1EGXhuPPvDW0WekxIbY5CiXUZbYw="
      "haras-releases.cachix.org-1:DK1D4cU3v6GUkdjynBsjk0cCMtLaueSUCD7wJBPxyMM="
      # cspell:enable
    ];
  };
}
