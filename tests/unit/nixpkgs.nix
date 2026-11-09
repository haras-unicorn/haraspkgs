{
  selfLib,
  ...
}:

let
  fakePackage = name: {
    pname = name;
  };
in
{
  self.unitTests.nixpkgs = {
    test-config-default = {
      expr = selfLib.nixpkgs.makeConfig { };
      expected = { };
    };

    test-config-passthrough = {
      expr = selfLib.nixpkgs.makeConfig {
        cudaSupport = true;
        rocmSupport = true;
      };
      expected = {
        cudaSupport = true;
        rocmSupport = true;
      };
    };

    test-config-unfree-names = {
      expr =
        let
          config = selfLib.nixpkgs.makeConfig {
            allowUnfreePackageNames = [ "foo" ];
          };
        in
        {
          foo = config.allowUnfreePredicate (fakePackage "foo");
          bar = config.allowUnfreePredicate (fakePackage "bar");
        };
      expected = {
        foo = true;
        bar = false;
      };
    };

    test-config-unfree-predicates = {
      expr =
        let
          config = selfLib.nixpkgs.makeConfig {
            allowUnfreePredicate = [ (package: package.pname == "foo") ];
          };
        in
        {
          foo = config.allowUnfreePredicate (fakePackage "foo");
          bar = config.allowUnfreePredicate (fakePackage "bar");
        };
      expected = {
        foo = true;
        bar = false;
      };
    };

    test-config-removes-helper-keys = {
      expr = builtins.attrNames (
        selfLib.nixpkgs.makeConfig {
          allowUnfreePackageNames = [ "foo" ];
          allowUnfreePredicate = [ ];
        }
      );
      expected = [ "allowUnfreePredicate" ];
    };

    test-extra-overlays-off = {
      expr = builtins.map (
        overlay:
        (overlay { config.cudaSupport = false; } { nixos-test-driver = "unpatched"; }).nixos-test-driver
      ) selfLib.nixpkgs.extraOverlays;
      expected = [ "unpatched" ];
    };

    test-extra-overlays-unset = {
      expr = builtins.map (
        overlay: (overlay { config = { }; } { nixos-test-driver = "unpatched"; }).nixos-test-driver
      ) selfLib.nixpkgs.extraOverlays;
      expected = [ "unpatched" ];
    };

    test-extra-overlays-on = {
      expr = builtins.map (
        overlay:
        (overlay { config.cudaSupport = true; } {
          nixos-test-driver.overrideAttrs = patch: (patch { } { patches = [ "existing" ]; }).patches;
        }).nixos-test-driver
      ) selfLib.nixpkgs.extraOverlays;
      expected = [
        [
          "existing"
          (./../../src/lib/nixpkgs/nixos-test-driver-gpu.patch)
        ]
      ];
    };
  };
}
