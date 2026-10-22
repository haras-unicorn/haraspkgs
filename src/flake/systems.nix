{
  self.flakeModules.systems = {
    self = false;
    flake = true;
    value = { lib, ... }: {
      systems = lib.mkDefault [
        "x86_64-linux" # NOTE: flake option default
        "aarch64-linux" # NOTE: flake option default
        "aarch64-darwin" # NOTE: flake option default
      ];
    };
  };
}
