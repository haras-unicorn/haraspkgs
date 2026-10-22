{
  self.devTests.format = {
    flake = true;
    value = {
      modules = [
        (
          { pkgs, ... }:
          let
            formatter = pkgs.writeShellScriptBin "test-formatter" ''
              for file in "$@"; do
                printf 'good\n' > "$file"
              done
            '';
          in
          {
            file."format-target.txt".text = "bad";
            file."raw-target.txt" = {
              text = "bad";
              format = false;
            };
            format.formatters.example = {
              packages = [ formatter ];
              command = "test-formatter";
              includes = [ "format-target.txt" ];
            };
          }
        )
      ];
      commands = [
        "grep -qx good format-target.txt"
        "grep -qx bad raw-target.txt"
        "dev format"
        "grep -qx good format-target.txt"
        "grep -qx bad raw-target.txt"
      ];
    };
  };
}
