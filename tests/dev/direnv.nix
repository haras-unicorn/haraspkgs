{
  self.devTests.direnv = {
    flake = true;
    value = {
      modules = [
        (
          { pkgs, ... }:
          {
            git.enable = true;
            direnv = {
              enable = true;
              extra = "dotenv_if_exists .env";
              watch = {
                files = [ "extra.nix" ];
                dirs = [
                  "src"
                  "tests"
                ];
              };
            };
            packages = [ pkgs.direnv ];
          }
        )
      ];
      commands = [
        "grep -qx 'dotenv_if_exists .env' .envrc"
        "grep -qx 'watch_file extra.nix' .envrc"
        "grep -qx 'watch_dir src' .envrc"
        "grep -qx 'watch_dir tests' .envrc"
        "grep -qx '/.direnv' .gitignore"
        "cp .envrc envrc.generated"
        ''
          # Stand in for `use flake` and the shell hook: it runs inside
          # `use flake`, takes longer than direnv's one second timestamp
          # resolution, and modifies a watched directory, as wrapped
          # formatters do. It also notes when the source files are not yet
          # watched, which is what nix-direnv checks for staleness.
          sed 's#^use flake .*#echo load >> load.log; direnv show_dump "$DIRENV_WATCHES" | grep -q src/dev/direnv.nix || echo unwatched >> unwatched.log; sleep 1.1; touch src/side-effect#' \
            .envrc > envrc.test
          mv envrc.test .envrc
          export XDG_DATA_HOME="$PWD/xdg-data" XDG_CONFIG_HOME="$PWD/xdg-config"
          direnv allow
          eval "$(direnv export bash)"
          eval "$(direnv export bash)"
          test "$(wc -l < load.log)" = 1
          test ! -e unwatched.log
          direnv show_dump "$DIRENV_WATCHES" | grep -q 'src/dev/direnv.nix'
          direnv show_dump "$DIRENV_WATCHES" | grep -q 'tests/dev/direnv.nix'
        ''
        ''
          line() { grep -n "$1" envrc.generated | head -n 1 | cut -d: -f1; }
          test "$(line '^watch_dir src')" -lt "$(line '^use flake')"
          test "$(grep -c '^watch_dir src$' envrc.generated)" = 2
          test "$(tail -n 1 envrc.generated)" = 'watch_dir tests'
        ''
      ];
    };
  };

  self.devTests.direnv-defaults = {
    flake = true;
    value = {
      modules = [ { direnv.enable = true; } ];
      commands = [
        "grep -qx 'use flake . --show-trace' .envrc"
        "grep -qx 'watch_dir src' .envrc"
        "grep -qx 'watch_dir tests' .envrc"
        ''test "$(grep -c '^watch_dir' .envrc)" = 4''
      ];
    };
  };
}
