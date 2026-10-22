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
      expr = selfLib.nixpkgs.makeExtraOverlays { cudaSupport = false; };
      expected = [ ];
    };

    test-extra-overlays-on = {
      expr =
        let
          overlays = selfLib.nixpkgs.makeExtraOverlays { cudaSupport = true; };
        in
        {
          count = builtins.length overlays;
          firstIsFunction = builtins.isFunction (builtins.head overlays);
        };
      expected = {
        count = 1;
        firstIsFunction = true;
      };
    };
  };
}
