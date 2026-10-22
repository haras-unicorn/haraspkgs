{
  self.devModules.license = {
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
        license = config.license;

        source =
          if license.source != null then
            license.source
          else
            "${license.package.text}/text/${license.spdx}.txt";

        licenseText = builtins.readFile source;

        renderedText =
          lib.replaceStrings (builtins.attrNames license.attrs) (builtins.attrValues license.attrs)
            licenseText;
      in
      {
        options.license = {
          enable = lib.mkEnableOption "license file";

          package = lib.mkPackageOption pkgs "spdx-license-list-data" { };

          spdx = lib.mkOption {
            type = lib.types.str;
            description = "SPDX identifier of the license to generate.";
          };

          source = lib.mkOption {
            type = lib.types.nullOr (lib.types.either lib.types.path lib.types.package);
            default = null;
            description = "Source license text file. Defaults to the SPDX text file.";
          };

          attrs = lib.mkOption {
            type = lib.types.attrsOf lib.types.str;
            default = { };
            description = "Placeholder-to-value substitutions in the license text.";
          };

          path = lib.mkOption {
            type = lib.types.str;
            default = "LICENSE";
            description = "Path of the generated license file.";
          };
        };

        config = lib.mkIf license.enable {
          file.${license.path} = {
            text = renderedText;
            format = false;
          };
        };
      };
  };
}
