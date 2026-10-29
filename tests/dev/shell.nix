{
  self.devTests.shell = {
    flake = true;
    value = {
      modules = [
        ({ pkgs, ... }: {
          packages = [ pkgs.hello ];
          env.EXAMPLE = "shell-value";
          shellHook = "echo example > shell-hook.txt";
        })
      ];
      commands = [
        ''test "$EXAMPLE" = shell-value''
        "grep -qx example shell-hook.txt"
        "hello --greeting shell-package"
      ];
    };
  };

  self.devTests.shell-overlay = {
    flake = true;
    value = {
      modules = [
        ({ pkgs, lib, ... }: {
          packages = lib.optional pkgs.stdenv.isLinux (
            pkgs.harasPackages.makeBubblewrapWrapper {
              name = "hello-wrapped";
              package = pkgs.hello;
            }
          );
        })
      ];
      commands = [
        ''if [ "$(uname)" = Linux ]; then test -e "$(command -v hello-wrapped)"; fi''
      ];
    };
  };

  self.devTests.shell-nixpkgs = {
    flake = true;
    value = {
      modules = [
        ({ pkgs, ... }: {
          nixpkgs.overlays = [
            (final: _prev: {
              example-overlay-package = final.hello;
            })
          ];
          packages = [ pkgs.example-overlay-package ];
        })
      ];
      commands = [ "hello --greeting overlay-ok" ];
    };
  };

  self.devTests.bwrap-files = {
    flake = true;
    value = {
      modules = [
        ({ pkgs, ... }: {
          bwrap.files = {
            "global-text.txt".text = "global-text\n";
            "global-source.txt".source = pkgs.writeText "global-source" "global-source\n";
          };
          packages = [
            (pkgs.harasPackages.makeBubblewrapWrapper {
              name = "read-binds";
              package = pkgs.writeShellScriptBin "read-binds" ''
                cat global-text.txt global-source.txt > out.txt
              '';
            })
          ];
        })
      ];
      commands = [
        "read-binds"
        "grep -qx global-text out.txt"
        "grep -qx global-source out.txt"
        "test ! -e global-text.txt"
        "test ! -e global-source.txt"
      ];
    };
  };

  self.devTests.bwrap-materialize = {
    flake = true;
    value = {
      modules = [
        ({ pkgs, ... }: {
          bwrap.files."materialized.txt".text = "materialized\n";
          packages = [
            (pkgs.harasPackages.makeBubblewrapWrapper {
              name = "read-materialized";
              package = pkgs.writeShellScriptBin "read-materialized" ''
                cat materialized.txt > out.txt
              '';
            })
          ];
        })
      ];
      commands = [
        "env -u NIX_BUILD_TOP HARASPKGS_MATERIALIZE=1 read-materialized"
        "grep -qx materialized out.txt"
        "test ! -e materialized.txt"
      ];
    };
  };
}
