{
  selfLib,
  ...
}:

{
  self.overlays.overlays.mcp-server-filesystem-bwrap = {
    flake = true;
    value =
      final: prev:
      let
        package = final.callPackage (
          {
            bwrapArgs ? null,
          }:
          let
            args = if bwrapArgs != null then bwrapArgs else selfLib.bwrap.local;
          in
          final.writeShellApplication {
            name = "mcp-server-filesystem-bwrap";
            runtimeInputs = [ final.bubblewrap ];
            text = ''
              mkdir -p "$FS_BASE_DIR"
              exec bwrap \
                ${final.lib.escapeShellArgs args} \
                --bind "$FS_BASE_DIR" "$FS_BASE_DIR" \
                --chdir "$FS_BASE_DIR" \
                --setenv HOME "$FS_BASE_DIR" \
                -- ${final.lib.getExe final.mcp-server-filesystem} "$FS_BASE_DIR" "$@"
            '';
            meta = {
              description = "mcp-server-filesystem wrapped with bubblewrap";
              mainProgram = "mcp-server-filesystem-bwrap";
            };
          }
        ) { };
      in
      {
        mcp-server-filesystem-bwrap = package;
      };
  };
}
