{
  config,
  inputs,
  lib,
  selfLib,
  ...
}:

let
  fixture = builtins.toFile "haraspkgs-flake-fixture.nix" ''
    { self, config, lib, ... }:
    {
      self.lib.exported = {
        flake = true;
        value = "exported";
      };

      self.lib.internal = {
        self = true;
        value = "internal";
      };

      self.lib.both = {
        self = true;
        flake = true;
        value = "both";
      };

      self.flakeModules.extra = {
        value = {
          self.lib.fromFlakeModule = {
            flake = true;
            value = true;
          };
        };
      };

      self.overlays.overlays.hello = {
        flake = true;
        value = final: _prev: {
          hello = final.runCommand "hello" {
            meta = {
              description = "hello";
              mainProgram = "hello";
            };
          } '''
            mkdir -p $out/bin
            printf '#!/bin/sh\necho hello\n' > $out/bin/hello
            chmod +x $out/bin/hello
          ''';
        };
      };

      self.devModules.example = {
        self = false;
        flake = false;
        value =
          { pkgs, ... }:
          {
            name = "example-dev-shell";
            packages =
              [ pkgs.hello ]
              ++ pkgs.lib.optional pkgs.stdenv.isLinux (
                pkgs.harasPackages.makeBubblewrapWrapper {
                  name = "hello-wrapped";
                  package = pkgs.hello;
                }
              );
            shellHook = [
              "echo example"
              {
                text = "echo nested";
                depth = 2;
              }
            ];
            file = {
              ".generated.txt".text = "generated";
              ".ensured.txt".ensure = "ensured";
              ".ignored.txt" = {
                text = "ignored";
                ignore = true;
              };
              ".linked.txt".source = builtins.toFile "example-linked.txt" "linked\n";
            };
            git = {
              enable = true;
              ignore.patterns = "*.log";
              attributes = "*.nix text";
              hooks = pkgs.lib.optionalAttrs pkgs.stdenv.isLinux {
                pre-commit.commands = "echo hook";
              };
            };
            passthru.checks.ok = pkgs.runCommand "example-ok" { } "touch $out";
          };
      };

      self.devModules.downstream = {
        value = { };
      };

      self.devShells.example = {
        value = {
          imports = [ config.self.devModules.example.value ];
        };
      };

      self.devTests.example = {
        flake = true;
        value = {
          modules = [
            config.self.devModules.example.value
            {
              shellHook = "echo dev-test-hook";
            }
          ];
          commands = [ "test -f .generated.txt" ];
        };
      };

      self.nixosTests.example = {
        flake = true;
        value =
          _:
          {
            containers.agent = { };
            testScript = "start_all()";
          };
      };

      self.containers.example = {
        value =
          _:
          {
            system.stateVersion = "26.05";
          };
      };

      self.benchmarks.example = {
        machine = "agent";
        service = "example.service";
        marker = "BENCHMARK";
        value =
          _:
          {
            containers.agent = { };
          };
      };

      self.nixpkgs.config = {
        allowUnfree = true;
      };

      self.nixpkgs.overlays = [
        (final: _prev: {
          from-user-overlay = final.hello;
        })
      ];

      self.lib.pkgsChecks = {
        flake = true;
        value = lib.genAttrs config.systems (system: {
          allowUnfree = config.self.lib.pkgs.''${system}.config.allowUnfree or false;
          fromUserOverlay = config.self.lib.pkgs.''${system} ? from-user-overlay;
        });
      };

      self.nixosConfigurations = lib.genAttrs config.systems (system: {
        flake = true;
        value =
          { ... }:
          {
            nixpkgs.system = system;
            networking.hostName = "machine";
            system.stateVersion = "26.05";
          };
      });

      self.homeConfigurations.home = {
        flake = true;
        value =
          { ... }:
          {
            home.stateVersion = "26.05";
          };
      };

    }
  '';

  outputs = selfLib.lib.makeFlake {
    inherit inputs;
    modules = [
      ../../src
      fixture
    ];
  };

  downstreamOutputs = selfLib.lib.makeFlake {
    inherit inputs;
    modules = [ fixture ];
  };

  minimalOutputs = selfLib.lib.makeFlake {
    inputs = {
      inherit (inputs) nixpkgs nix-unit;
    };
    modules = [ ];
  };
in
{
  self.lib.test = {
    flake = false;
    value = {
      devModules = outputs.devModules;
      devShells = lib.genAttrs config.systems (system: outputs.lib.${system}.devShells);
    };
  };

  self.unitTests.flake = {
    test-output-contract = {
      expr = {
        hasLib = outputs ? lib;
        hasFlakeModules = outputs ? flakeModules;
        hasDevShells = outputs ? devShells;
        hasDevTests = builtins.all (system: outputs.lib.${system} ? devTests) config.systems;
        hasPackages = outputs ? packages;
        hasChecks = outputs ? checks;
        hasNixosConfigurations = outputs ? nixosConfigurations;
        hasHomeConfigurations = outputs ? homeConfigurations;
      };
      expected = {
        hasLib = true;
        hasFlakeModules = true;
        hasDevShells = true;
        hasDevTests = true;
        hasPackages = true;
        hasChecks = true;
        hasNixosConfigurations = true;
        hasHomeConfigurations = true;
      };
    };

    test-downstream-only-output-contract = {
      expr = {
        hasLib = downstreamOutputs ? lib;
        hasDevShells = downstreamOutputs ? devShells;
        hasPackages = downstreamOutputs ? packages;
        hasChecks = downstreamOutputs ? checks;
        hasOverlays = downstreamOutputs ? overlays;
        hasNixosConfigurations = downstreamOutputs ? nixosConfigurations;
      };
      expected = {
        hasLib = true;
        hasDevShells = true;
        hasPackages = true;
        hasChecks = true;
        hasOverlays = true;
        hasNixosConfigurations = true;
      };
    };

    test-downstream-only-self-modules = {
      expr = builtins.length downstreamOutputs.lib.selfModules;
      expected = 1;
    };

    test-downstream-inputs-fallback = {
      expr = {
        hasLib = minimalOutputs ? lib;
        hasFlakeModules = minimalOutputs ? flakeModules;
        hasDevShells = minimalOutputs ? devShells;
        hasPackages = minimalOutputs ? packages;
        hasChecks = minimalOutputs ? checks;
        hasOverlays = minimalOutputs ? overlays;
        hasNixosConfigurations = minimalOutputs ? nixosConfigurations;
      };
      expected = {
        hasLib = true;
        hasFlakeModules = true;
        hasDevShells = true;
        hasPackages = true;
        hasChecks = true;
        hasOverlays = true;
        hasNixosConfigurations = true;
      };
    };

    test-self-flake-flags = {
      expr = {
        hasExported = outputs.lib ? exported;
        hasBoth = outputs.lib ? both;
        hasInternal = outputs.lib ? internal;
      };
      expected = {
        hasExported = true;
        hasBoth = true;
        hasInternal = false;
      };
    };

    test-all-core-flake-modules-exported = {
      expr = builtins.all (name: outputs.flakeModules ? ${name}) [
        "assertions"
        "base"
        "benchmarks"
        "containers"
        "dev"
        "dev-tests"
        "machines"
        "nixos-tests"
        "nixpkgs"
        "systems"
        "unit-tests"
      ];
      expected = true;
    };

    test-flake-modules-default-group = {
      expr =
        builtins.isList outputs.flakeModules.default.imports
        && builtins.length outputs.flakeModules.default.imports == 11;
      expected = true;
    };

    test-all-core-dev-modules-exported = {
      expr = builtins.all (name: outputs.devModules ? ${name}) [
        "check"
        "cli"
        "code-of-conduct"
        "editorconfig"
        "file"
        "git"
        "gitleaks"
        "languages"
        "license"
        "shell"
        "workflows"
      ];
      expected = true;
    };

    test-core-modules-not-in-self = {
      expr = builtins.length outputs.lib.selfModules == 1;
      expected = true;
    };

    test-downstream-dev-module-stays-in-self = {
      expr = {
        inSelf = outputs.lib.devModules ? downstream;
        inFlake = outputs.devModules ? downstream;
      };
      expected = {
        inSelf = true;
        inFlake = false;
      };
    };

    test-downstream-flake-module-imported = {
      expr = {
        imported = outputs.lib ? fromFlakeModule;
        inSelf = outputs.flakeModules ? extra;
      };
      expected = {
        imported = true;
        inSelf = false;
      };
    };

    test-flake-lib-values = {
      expr = {
        exported = outputs.lib.exported.value;
        both = outputs.lib.both.value;
      };
      expected = {
        exported = "exported";
        both = "both";
      };
    };

    test-internal-not-exported = {
      expr = outputs.lib ? internal;
      expected = false;
    };

    test-overlay-flake-output = {
      expr = outputs.overlays ? hello;
      expected = true;
    };

    test-home-configuration = {
      expr = outputs.homeConfigurations ? home;
      expected = true;
    };
  };

  perSystem =
    { system, pkgs, ... }:
    {
      self.unitTests.flake-system = {
        test-downstream-only-overlay-package = {
          expr = downstreamOutputs.packages.${system} ? hello;
          expected = true;
        };

        test-downstream-only-overlay-app = {
          expr = downstreamOutputs.apps.${system} ? hello;
          expected = true;
        };

        test-downstream-only-dev-shell = {
          expr = downstreamOutputs.lib.${system}.devShells ? example;
          expected = true;
        };

        test-nixpkgs-config = {
          expr = outputs.lib.pkgsChecks.value.${system}.allowUnfree;
          expected = true;
        };

        test-nixpkgs-overlay = {
          expr = outputs.lib.pkgsChecks.value.${system}.fromUserOverlay;
          expected = true;
        };

        test-nixos-configuration = {
          expr = outputs.nixosConfigurations.${system}.config.networking.hostName;
          expected = "machine";
        };
      }
      // lib.optionalAttrs pkgs.stdenv.isLinux {
        test-nixos-test-check = {
          expr = outputs.checks.${system} ? nixos-test-example;
          expected = true;
        };

        test-container-is-function = {
          expr = builtins.isFunction outputs.lib.containers.${system}.example;
          expected = true;
        };

        test-container-realized = {
          expr = (outputs.lib.containers.${system}.example { }) ? nspawn;
          expected = true;
        };

        test-benchmark-is-function = {
          expr = builtins.isFunction outputs.lib.benchmarks.${system}.example;
          expected = true;
        };

        test-benchmark-realized = {
          expr = (outputs.lib.benchmarks.${system}.example { }).drvPath != "";
          expected = true;
        };
      };

      self.unitTests.devTests = {
        test-dev-test-lib = {
          expr = outputs.lib.${system}.devTests ? example;
          expected = true;
        };

        test-dev-test-check = {
          expr = outputs.checks.${system} ? dev-test-example;
          expected = true;
        };

        test-dev-test-name = {
          expr = outputs.lib.${system}.devTests.example.name;
          expected = "dev-test-example";
        };
      };
    };
}
