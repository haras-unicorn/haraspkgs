{
  self.devModules.languages = {
    self = false;
    flake = true;
    value = { lib, ... }: {
      options.languages = {
        servers = lib.mkOption {
          default = { };
          description = "Language server definitions used to configure editors.";
          type = lib.types.attrsOf (
            lib.types.submodule {
              options = {
                command = lib.mkOption {
                  type = lib.types.str;
                  description = "Command used to start the server.";
                };

                arguments = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [ ];
                  description = "Extra arguments passed to the server.";
                };

                config = lib.mkOption {
                  type = lib.types.anything;
                  default = { };
                  description = "Configuration passed to the server through LSP.";
                };
              };
            }
          );
        };

        languages = lib.mkOption {
          default = { };
          description = "Language definitions used to configure editors.";
          type = lib.types.attrsOf (
            lib.types.submodule {
              options = {
                servers = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [ ];
                  description = "Names of servers used with this language.";
                };

                auto-format = lib.mkOption {
                  type = lib.types.bool;
                  default = true;
                  description = "Whether to automatically format files for this language.";
                };

                formatter = lib.mkOption {
                  type = lib.types.nullOr (
                    lib.types.submodule {
                      options = {
                        command = lib.mkOption {
                          type = lib.types.str;
                          description = "Formatter command to run.";
                        };

                        arguments = lib.mkOption {
                          type = lib.types.listOf lib.types.str;
                          default = [ ];
                          description = "Formatter command arguments.";
                        };
                      };
                    }
                  );
                  default = null;
                  description = "Formatter used for this language.";
                };
              };
            }
          );
        };
      };
    };
  };
}
