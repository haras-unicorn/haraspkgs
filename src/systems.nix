{
  config = {
    systems = [
      "x86_64-linux" # NOTE: haraspkgs systems
      "aarch64-linux" # NOTE: haraspkgs systems
      "aarch64-darwin" # NOTE: haraspkgs systems
    ];

    self.overlays.namespace = "harasPackages";
    self.lib.overlays.namespace = "harasPackages";
  };
}
