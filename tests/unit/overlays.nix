{
  self,
  selfLib,
  ...
}:

let
  overlays = selfLib.overlays;

  graph = {
    base = {
      name = "base";
      deps = [ ];
      value = _final: _prev: {
        base = "base";
      };
    };

    a = {
      name = "a";
      deps = [ "base" ];
      value = _final: prev: {
        a = prev.base + "-a";
      };
    };

    b = {
      name = "b";
      deps = [ "base" ];
      value = _final: prev: {
        b = prev.base + "-b";
      };
    };

    c = {
      name = "c";
      deps = [
        "a"
        "b"
      ];
      value = _final: prev: {
        c = prev.a + "-" + prev.b;
      };
    };

    regex = {
      name = "regex";
      deps = [ "/a|b/" ];
      value = _final: prev: {
        regex = prev.a + "-" + prev.b;
      };
    };
  };

  cycleGraph = {
    cycle-a = {
      name = "cycle-a";
      deps = [ "cycle-b" ];
      value = _final: _prev: { };
    };

    cycle-b = {
      name = "cycle-b";
      deps = [ "cycle-a" ];
      value = _final: _prev: { };
    };
  };

  missingGraph = {
    missing = {
      name = "missing";
      deps = [ "nope" ];
      value = _final: _prev: { };
    };
  };

  composed = (overlays.composeOverlay graph graph) { } { };
in
{
  self.unitTests.overlays = {
    test-matching-exact = {
      expr = overlays.matching "base" "base";
      expected = true;
    };

    test-matching-regex = {
      expr = overlays.matching "/a|b/" "b";
      expected = true;
    };

    test-matching-miss = {
      expr = overlays.matching "base" "other";
      expected = false;
    };

    test-direct-deps = {
      expr = overlays.directDeps graph "c";
      expected = [
        "a"
        "b"
      ];
    };

    test-transitive-deps = {
      expr = overlays.transitiveDeps graph "c";
      expected = [
        "a"
        "b"
        "base"
      ];
    };

    test-compose-order = {
      expr = composed.c;
      expected = "base-a-base-b";
    };

    test-compose-regex = {
      expr = composed.regex;
      expected = "base-a-base-b";
    };

    test-cycle-detected = {
      expr = (builtins.tryEval (overlays.transitiveDeps cycleGraph "cycle-a")).success;
      expected = false;
    };

    test-undefined-detected = {
      expr = (builtins.tryEval (overlays.transitiveDeps missingGraph "missing")).success;
      expected = false;
    };

    test-undefined-assertion = {
      expr = overlays.makeUndefinedDepsAssertion missingGraph;
      expected = {
        assertion = false;
        message = "Dependencies nope -> missing of overlays are undefined";
      };
    };

    test-undefined-assertion-success = {
      expr = overlays.makeUndefinedDepsAssertion graph;
      expected = {
        assertion = true;
        message = "All overlay dependencies are defined";
      };
    };

    test-namespace-overlay = {
      expr =
        let
          result = (overlays.namespaceOverlay "pkg" (_final: _prev: { hello = "world"; })) { } {
            pkg.existing = "kept";
          };
        in
        {
          inherit (result.pkg) existing hello;
        };
      expected = {
        existing = "kept";
        hello = "world";
      };
    };

    test-overlay-list = {
      expr = builtins.length (
        overlays.overlayList {
          a.value = _final: _prev: { };
          b.value = _final: _prev: { };
        }
      );
      expected = 2;
    };
  };

  perSystem =
    { pkgs, ... }:
    let
      shellPkgs = pkgs.extend self.overlays.shell;
      devPkgs = pkgs.extend self.overlays.dev;
    in
    {
      self.unitTests.shellOverlay = {
        test-exported = {
          expr = self.overlays ? shell;
          expected = true;
        };

        test-helper = {
          expr = shellPkgs.harasPackages ? makeBubblewrapWrapper;
          expected = true;
        };

        test-in-base-pkgs = {
          expr = (pkgs.harasPackages or { }) ? makeBubblewrapWrapper;
          expected = true;
        };
      };

      self.unitTests.devOverlay = {
        test-exported = {
          expr = self.overlays ? dev;
          expected = true;
        };

        test-helpers = {
          expr = devPkgs.harasPackages ? makeDevTest && devPkgs.harasPackages ? evaluateDevShellAttrs;
          expected = true;
        };
      };
    };
}
