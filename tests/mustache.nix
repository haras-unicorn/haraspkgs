{
  perSystem =
    { pkgs, ... }:
    let
      arguments = {
        name = "haraspkgs-mustache-check";
        text = ''
          host={{host}}
          raw={{{raw}}}
          {{#ports}}
          port={{.}}
          {{/ports}}
        '';
        vars = {
          host = "example.org";
          raw = "a&b";
          ports = [
            80
            443
          ];
        };
      };

      expected = ''
        host=example.org
        raw=a&b
        port=80
        port=443
      '';

      file = pkgs.harasPackages.renderMustache arguments;
      text = pkgs.harasPackages.renderMustacheText arguments;
    in
    {
      checks.mustache-render-file = pkgs.runCommand "haraspkgs-mustache-render-file" { } ''
        diff ${file} ${pkgs.writeText "expected" expected}
        touch "$out"
      '';

      checks.mustache-render-text = pkgs.runCommand "haraspkgs-mustache-render-text" { } ''
        diff ${pkgs.writeText "rendered" text} ${pkgs.writeText "expected" expected}
        touch "$out"
      '';
    };
}
