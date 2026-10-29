{ selfLib, ... }:

let
  inherit (selfLib) flattenInputs;

  leaf = {
    name = "leaf";
  };

  middle = {
    name = "middle";
    inputs = {
      inherit leaf;
    };
  };

  root = {
    name = "root";
    inputs = {
      inherit middle;
      other = leaf;
    };
  };
in
{
  self.unitTests.flatten-inputs = {
    test-empty = {
      expr = flattenInputs { };
      expected = { };
    };

    test-keeps-inputs-without-nested-inputs = {
      expr = flattenInputs { inherit leaf; };
      expected = {
        inherit leaf;
      };
    };

    test-includes-nested-inputs-by-path = {
      expr = builtins.attrNames (flattenInputs {
        inherit middle;
      });
      expected = [
        "middle"
        "middle/leaf"
      ];
    };

    test-goes-through-the-entire-hierarchy = {
      expr = builtins.attrNames (flattenInputs {
        inherit root;
      });
      expected = [
        "root"
        "root/middle"
        "root/middle/leaf"
        "root/other"
      ];
    };

    test-keeps-values = {
      expr = (flattenInputs { inherit root; })."root/middle/leaf";
      expected = leaf;
    };

    test-does-not-skip-nixpkgs = {
      expr = builtins.attrNames (flattenInputs {
        a.inputs.nixpkgs = leaf;
      });
      expected = [
        "a"
        "a/nixpkgs"
      ];
    };
  };
}
