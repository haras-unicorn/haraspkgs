{
  self.devTests.check = {
    flake = true;
    value = {
      modules = [
        ({ pkgs, ... }: {
          check.checks.example = {
            packages = [ pkgs.hello ];
            commands = "hello --greeting check-ok > check.txt";
          };
        })
      ];
      commands = [
        "dev check"
        "grep -qx 'check-ok' check.txt"
      ];
    };
  };

  self.devTests.check-podman = {
    flake = true;
    value = {
      podman.enable = true;
      modules = [
        ({ pkgs, ... }: {
          check.checks.example = {
            podman = {
              enable = true;
              images = [
                (pkgs.dockerTools.buildImage {
                  name = "container-probe";
                  tag = "latest";
                  copyToRoot = [ pkgs.busybox ];
                  config.Cmd = [
                    "/bin/echo"
                    "hello from the container"
                  ];
                })
              ];
            };
            commands = ''
              image=localhost/container-probe:latest
              podman --remote run --rm "$image" > check.txt
            '';
          };
        })
      ];
      commands = [
        "dev check"
        "grep -qx 'hello from the container' check.txt"
      ];
    };
  };
}
