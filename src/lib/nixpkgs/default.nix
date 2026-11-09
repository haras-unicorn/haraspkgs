{ lib, ... }:

{
  self.lib.nixpkgs = {
    extraOverlays = [
      (final: prev: {
        # NOTE: the condition has to be in the value and not around the
        # attribute, because `final.config` is only available once the names of
        # the overlays are known.
        nixos-test-driver =
          if final.config.cudaSupport or false then
            prev.nixos-test-driver.overrideAttrs (
              final: prev: {
                patches = (prev.patches or [ ]) ++ [ ./nixos-test-driver-gpu.patch ];
              }
            )
          else
            prev.nixos-test-driver;
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
