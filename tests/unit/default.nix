{
  lib,
  selfLib,
  ...
}:

let
  helpers = selfLib.lib;
in
{
  self.unitTests.default = {
    test-filter-by-key-keeps-default = {
      expr = helpers.filterAttrsByKey "self" true {
        a = {
          self = true;
        };
        b = {
          self = false;
        };
        c = { };
      };
      expected = {
        a = {
          self = true;
        };
        c = { };
      };
    };

    test-filter-by-key-keeps-explicit = {
      expr = helpers.filterAttrsByKey "flake" false {
        a = {
          flake = true;
        };
        b = {
          flake = false;
        };
        c = { };
      };
      expected = {
        a = {
          flake = true;
        };
      };
    };

    test-filter-by-keys = {
      expr = builtins.attrNames (
        helpers.filterAttrsByKeys [ "self" "flake" ] {
          self = 1;
          flake = 2;
          value = 3;
        }
      );
      expected = [ "value" ];
    };

    test-filter-recursive-by-key = {
      expr = helpers.filterAttrsRecursiveByKey "self" true {
        keep = {
          self = true;
          value = {
            self = true;
            leaf = 1;
          };
        };
        drop = {
          self = false;
          leaf = 2;
        };
      };
      expected = {
        keep = {
          self = true;
          value = {
            self = true;
            leaf = 1;
          };
        };
        drop = {
          self = false;
          leaf = 2;
        };
      };
    };

    test-filter-recursive-by-keys = {
      expr = helpers.filterAttrsRecursiveByKeys [ "self" "flake" ] {
        self = 1;
        flake = 2;
        nested = {
          self = 3;
          value = 4;
        };
      };
      expected = {
        self = 1;
        flake = 2;
        nested = {
          value = 4;
        };
      };
    };

    test-filter-recursive-by-key-stops-at-flake = {
      expr =
        let
          result = helpers.filterAttrsRecursiveByKey "self" true {
            inputs = {
              nix-unit = {
                _type = "flake";
                outputs = throw "flake outputs should not be forced";
              };
            };
          };
        in
        builtins.attrNames result.inputs.nix-unit;
      expected = [
        "_type"
        "outputs"
      ];
    };

    test-filter-recursive-by-keys-stops-at-flake = {
      expr =
        let
          result = helpers.filterAttrsRecursiveByKeys [ "self" "flake" ] {
            inputs = {
              nix-unit = {
                _type = "flake";
                outputs = throw "flake outputs should not be forced";
              };
            };
          };
        in
        builtins.attrNames result.inputs.nix-unit;
      expected = [
        "_type"
        "outputs"
      ];
    };

    test-make-module-attrs = {
      expr = helpers.makeModuleAttrs {
        a = {
          value = {
            imports = [ ];
            flag = 1;
          };
        };
        b = {
          value = {
            imports = [ ];
            flag = 2;
          };
        };
      };
      expected = {
        a = {
          imports = [ ];
          flag = 1;
        };
        b = {
          imports = [ ];
          flag = 2;
        };
        default.imports = [
          {
            imports = [ ];
            flag = 1;
          }
          {
            imports = [ ];
            flag = 2;
          }
        ];
      };
    };

    test-recursive-attrs-type-merges-attrs = {
      expr =
        helpers.recursiveAttrsType.merge
          [ ]
          [
            {
              value = {
                a = 1;
                nested.b = 2;
              };
            }
            {
              value = {
                c = 3;
                nested.d = 4;
              };
            }
          ];
      expected = {
        a = 1;
        c = 3;
        nested = {
          b = 2;
          d = 4;
        };
      };
    };

    test-recursive-attrs-type-merges-lists = {
      expr =
        helpers.recursiveAttrsType.merge
          [ ]
          [
            {
              value = {
                list = [ 1 ];
                nested.list = [ "a" ];
              };
            }
            {
              value = {
                list = [ 2 ];
                nested.list = [ "b" ];
              };
            }
          ];
      expected = {
        list = [
          1
          2
        ];
        nested.list = [
          "a"
          "b"
        ];
      };
    };

    test-self-functor = {
      expr =
        let
          configured = helpers.selfFunctor {
            flake = true;
            functor = value: value;
          };
          callable = configured {
            self = false;
            flake = true;
          };
        in
        {
          configuredFlake = configured.flake;
          callableSelf = callable.self;
          callableFlake = callable.flake;
        };
      expected = {
        configuredFlake = true;
        callableSelf = false;
        callableFlake = true;
      };
    };

    test-lib-exports = {
      expr = lib.sort builtins.lessThan (builtins.attrNames helpers);
      expected = [
        "baseModule"
        "filterAttrsByKey"
        "filterAttrsByKeys"
        "filterAttrsRecursiveByKey"
        "filterAttrsRecursiveByKeys"
        "inputs"
        "makeFlake"
        "makeModuleAttrs"
        "mergeRecursiveAttrs"
        "recursiveAttrsType"
        "selfFunctor"
        "selfSubmodule"
      ];
    };
  };
}
