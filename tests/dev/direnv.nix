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
          # Stand in for the shell hook: it runs inside `use flake`, takes
          # longer than direnv's one second timestamp resolution, and
          # modifies a watched directory, as wrapped formatters do.
          sed 's|^use flake .*|echo load >> load.log; sleep 1.1; touch src/side-effect|' \
            .envrc > envrc.test
          mv envrc.test .envrc
          export XDG_DATA_HOME="$PWD/xdg-data" XDG_CONFIG_HOME="$PWD/xdg-config"
          direnv allow
          eval "$(direnv export bash)"
          eval "$(direnv export bash)"
          test "$(wc -l < load.log)" = 1
          direnv show_dump "$DIRENV_WATCHES" | grep -q 'src/dev/direnv.nix'
          direnv show_dump "$DIRENV_WATCHES" | grep -q 'tests/dev/direnv.nix'
        ''
        ''test "$(sed -n 2p envrc.generated)" = 'use flake . --show-trace' ''
      ];
    };
  };

  self.devTests.direnv-defaults = {
    flake = true;
    value = {
      modules = [ { direnv.enable = true; } ];
      commands = [
        ''test "$(cat .envrc)" = "$(printf 'use flake . --show-trace\nwatch_dir src\nwatch_dir tests')"''
      ];
    };
  };
}
