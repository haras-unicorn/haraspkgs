{
  self.devTests.editorconfig = {
    flake = true;
    value = {
      modules = [
        ({ pkgs, ... }: {
          editorconfig = {
            enable = true;
            path = "example.editorconfig";
            settings."*" = {
              charset = "utf-8";
              indent_size = 2;
              insert_final_newline = true;
            };
          };
          packages = [
            (pkgs.harasPackages.makeBubblewrapWrapper {
              name = "read-editorconfig";
              package = pkgs.writeShellScriptBin "read-editorconfig" "cat example.editorconfig";
            })
          ];
        })
      ];
      commands = [
        "read-editorconfig | grep -qx 'root = true'"
        "read-editorconfig | grep -qx 'charset = utf-8'"
        "read-editorconfig | grep -qx 'indent_size = 2'"
        "read-editorconfig | grep -qx 'insert_final_newline = true'"
        "test ! -e example.editorconfig"
      ];
    };
  };

  self.devTests.editorconfig-disabled = {
    flake = true;
    value = {
      modules = [ { editorconfig.enable = false; } ];
      commands = [ "test ! -e example.editorconfig" ];
    };
  };
}
