{
  ...
}:

{
  perSystem =
    { pkgs, lib, ... }:
    {
      checks = {
        flake-root-package = pkgs.runCommand "haraspkgs-flake-root-check" { } ''
          project="$PWD/project"
          mkdir -p "$project/sub/dir"
          touch "$project/flake.nix"

          actual="$(cd "$project/sub/dir" && ${lib.getExe pkgs.harasPackages.flake-root})"
          expected="$(cd "$project" && pwd -P)"

          if [[ "$actual" != "$expected" ]]; then
            echo "flake-root printed '$actual', expected '$expected'" >&2
            exit 1
          fi

          echo "$actual" > "$out"
        '';
      };
    };
}
