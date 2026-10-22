{ lib, ... }:

{
  self.lib.nixpkgs = {
    makeExtraOverlays =
      {
        cudaSupport ? false,
        ...
      }:
      lib.optionals cudaSupport [
        (final: prev: {
          nixos-test-driver = prev.nixos-test-driver.overrideAttrs (
            final: prev: {
              patches = (prev.patches or [ ]) ++ [ ./nixos-test-driver-gpu.patch ];
            }
          );
        })
      ];

    makeConfig =
      {
        allowUnfreePackageNames ? [ ],
        allowUnfreePredicate ? [ ],
        ...
      }@config:
      (builtins.removeAttrs config [
        "allowUnfreePackageNames"
        "allowUnfreePredicate"
        "allowUnfreePredicates"
      ])
      // lib.optionalAttrs (allowUnfreePackageNames != [ ] || allowUnfreePredicate != [ ]) {
        allowUnfreePredicate =
          package:
          lib.any (name: lib.getName package == name) allowUnfreePackageNames
          || lib.any (predicate: predicate package) allowUnfreePredicate;

      };
  };
}
