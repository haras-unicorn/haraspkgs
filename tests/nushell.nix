{
  ...
}:

{
  perSystem =
    { pkgs, lib, ... }:
    let
      app = pkgs.harasPackages.writeNushellApplication {
        name = "haraspkgs-nushell-check";
        runtimeInputs = [ pkgs.hello ];
        text = ''
          ^hello --greeting $env.HARASPKGS_CHECK
        '';
        environment.HARASPKGS_CHECK = "haraspkgs-nushell-ok";
      };
    in
    {
      checks.nushell-write-application = pkgs.runCommand "haraspkgs-nushell-write-application" { } ''
        ${lib.getExe app} > "$out"
        grep -q "haraspkgs-nushell-ok" "$out"
      '';
    };
}
