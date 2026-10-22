{
  self.overlays.overlays.ssh-test-container = {
    flake = true;
    value = final: prev: {
      ssh-test-container = final.writeShellApplication {
        name = "ssh-test-container";
        runtimeInputs = [
          final.openssh
          final.socat
        ];
        text = ''
          name="$1"
          shift
          ssh \
            -o User=root \
            -o ProxyCommand="socat - UNIX-CLIENT:/run/systemd/nspawn/unix-export/$name/ssh" \
            -o "UserKnownHostsFile=/dev/null" \
            -o "StrictHostKeyChecking=accept-new" \
            bash "$@"
        '';
      };
    };
  };
}
