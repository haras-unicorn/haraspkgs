{
  lib,
  selfLib,
  ...
}:

{
  self.unitTests.workflows = {
    test-render-base = {
      expr =
        let
          yaml = selfLib.workflows.render "docs" {
            installable = ".#docs";
            on.push.branches = [ "main" ];
            cachix = {
              name = "haras";
              extraPullNames = "haras-releases";
              authToken = "token";
            };
          };
        in
        lib.hasInfix "actions/checkout@v4" yaml
        && lib.hasInfix "cachix/install-nix-action@v31" yaml
        && lib.hasInfix "cachix/cachix-action@v15" yaml
        && lib.hasInfix "nix build --show-trace .#docs" yaml
        && lib.hasInfix ''"main"'' yaml;
      expected = true;
    };

    test-render-matrix = {
      expr =
        let
          yaml = selfLib.workflows.render "check" {
            installable = null;
            matrix.os = [
              "ubuntu-latest"
              "macos-latest"
            ];
          };
        in
        lib.hasInfix "\${{ matrix.os }}" yaml
        && lib.hasInfix "strategy" yaml
        && lib.hasInfix ''"macos-latest"'' yaml;
      expected = true;
    };

    test-render-permissions = {
      expr =
        let
          yaml = selfLib.workflows.render "docs" {
            installable = null;
            permissions.pages = "write";
          };
        in
        lib.hasInfix ''"contents":"read"'' yaml && lib.hasInfix ''"pages":"write"'' yaml;
      expected = true;
    };

    test-render-extra-steps = {
      expr =
        let
          yaml = selfLib.workflows.render "check" {
            installable = null;
            steps = [ { run = "echo extra-step"; } ];
          };
        in
        lib.hasInfix "echo extra-step" yaml;
      expected = true;
    };

    test-render-null-installable = {
      expr =
        let
          yaml = selfLib.workflows.render "check" { installable = null; };
        in
        !(lib.hasInfix "nix build" yaml);
      expected = true;
    };

    test-render-without-nix = {
      expr =
        let
          yaml = selfLib.workflows.render "release" {
            installable = null;
            installNix = false;
            cachix = null;
          };
        in
        !(lib.hasInfix "install-nix-action" yaml) && !(lib.hasInfix "cachix-action" yaml);
      expected = true;
    };

    test-render-extra-jobs = {
      expr =
        let
          yaml = selfLib.workflows.render "release" {
            installable = null;
            jobs.extra = {
              "runs-on" = "ubuntu-latest";
              steps = [ ];
            };
          };
        in
        lib.hasInfix ''"extra"'' yaml;
      expected = true;
    };
  };
}
