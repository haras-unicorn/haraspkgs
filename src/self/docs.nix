{
  perSystem =
    { pkgs, ... }:
    {
      packages.docs = pkgs.runCommand "haraspkgs-docs" { nativeBuildInputs = [ pkgs.mdbook ]; } ''
        mdbook build -d "$out" ${../../docs}
      '';
    };
}
