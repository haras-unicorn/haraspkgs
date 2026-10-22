{
  self.devModules.editorconfig = {
    self = false;
    flake = true;
    value =
      {
        config,
        lib,
        ...
      }:
      let
        settings = config.editorconfig.settings;

        renderValue =
          value: if builtins.isBool value then (if value then "true" else "false") else toString value;

        renderGlob =
          glob:
          let
            entries = lib.mapAttrsToList (name: value: "${name} = ${renderValue value}") settings.${glob};
          in
          ''
            [${glob}]
            ${lib.concatStringsSep "\n" entries}
          '';

        settingsText =
          "root = true\n\n"
          + lib.concatStringsSep "\n\n" (builtins.map renderGlob (builtins.attrNames settings));
      in
      {
        options.editorconfig = {
          enable = lib.mkEnableOption "EditorConfig file";

          path = lib.mkOption {
            type = lib.types.str;
            default = ".editorconfig";
            description = "Path of the generated EditorConfig file.";
          };

          settings = lib.mkOption {
            type = lib.types.attrsOf (
              lib.types.attrsOf (
                lib.types.oneOf [
                  lib.types.str
                  lib.types.int
                  lib.types.bool
                ]
              )
            );
            default = { };
            description = "EditorConfig sections keyed by glob.";
          };
        };

        config = lib.mkIf config.editorconfig.enable {
          bwrap.files.${config.editorconfig.path}.text = settingsText;
        };
      };
  };
}
