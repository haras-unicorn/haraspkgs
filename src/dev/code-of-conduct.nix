{
  self.devModules.code-of-conduct = {
    self = false;
    flake = true;
    value =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        covenant = config.codeOfConduct.contributorCovenant;

        urlVersion = builtins.replaceStrings [ "." ] [ "/" ] covenant.version;

        source =
          if covenant.source != null then
            covenant.source
          else
            pkgs.fetchurl {
              url = "https://www.contributor-covenant.org/version/${urlVersion}/code_of_conduct/code_of_conduct.md";
              hash = covenant.hash;
            };
      in
      {
        options.codeOfConduct.contributorCovenant = {
          enable = lib.mkEnableOption "Contributor Covenant code of conduct file";

          version = lib.mkOption {
            type = lib.types.str;
            default = "3.0";
            description = "Contributor Covenant version.";
          };

          hash = lib.mkOption {
            type = lib.types.str;
            default = "sha256-7T+AiSYuoE3lnQiaJnv6CCK5PJasWmXQZH/XZ6JchCI=";
            description = "Hash of the Contributor Covenant file.";
          };

          source = lib.mkOption {
            type = lib.types.nullOr (lib.types.either lib.types.path lib.types.package);
            default = null;
            description = "Source file to use instead of the configured version and hash.";
          };

          path = lib.mkOption {
            type = lib.types.str;
            default = "CODE_OF_CONDUCT.md";
            description = "Path of the generated code of conduct file.";
          };
        };

        config = lib.mkIf covenant.enable {
          file.${covenant.path}.text = builtins.readFile source;
        };
      };
  };
}
