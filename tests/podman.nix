{
  perSystem =
    { lib, pkgs, ... }:
    let
      ports = [
        8081
        8082
      ];

      connectTimeout = 30;

      probeImage = pkgs.dockerTools.buildImage {
        name = "container-probe";
        tag = "latest";
        copyToRoot = [ pkgs.busybox ];
        config.Cmd = [
          "/bin/echo"
          "hello from the container"
        ];
      };

      python = pkgs.python3.withPackages (packages: [
        packages.pg8000
        packages.testcontainers
      ]);

      # The client connects to 127.0.0.1 and not to the name the library
      # reports, because the sandbox has no /etc/hosts to resolve localhost
      # with. Two containers run at once on the same container port, which is
      # what host networking could not do. The first "ready" in the log is the
      # temporary server of the image entrypoint, so the client retries.
      postgresScript = pkgs.writeText "postgres-probe.py" ''
        import time

        import pg8000.exceptions
        import pg8000.native
        from testcontainers.core.container import DockerContainer
        from testcontainers.core.wait_strategies import LogMessageWaitStrategy


        def postgres():
            container = DockerContainer("postgres:18")
            container.with_exposed_ports(5432)
            container.with_env("POSTGRES_PASSWORD", "secret")
            container.waiting_for(
                LogMessageWaitStrategy("database system is ready to accept connections")
            )
            return container


        def connect(container):
            deadline = time.monotonic() + 30
            while True:
                try:
                    return pg8000.native.Connection(
                        user="postgres",
                        password="secret",
                        host="127.0.0.1",
                        port=int(container.get_exposed_port(5432)),
                    )
                except pg8000.exceptions.InterfaceError:
                    if time.monotonic() > deadline:
                        raise
                    time.sleep(0.2)


        def query(container):
            connection = connect(container)
            connection.run("create table probe (id integer primary key, name text)")
            connection.run("insert into probe values (1, 'hello'), (2, 'world')")
            rows = connection.run("select id, name from probe order by id")
            connection.close()
            return rows


        with postgres() as first, postgres() as second:
            ports = {first.get_exposed_port(5432), second.get_exposed_port(5432)}
            assert len(ports) == 2, ports
            for container in (first, second):
                rows = query(container)
                assert rows == [[1, "hello"], [2, "world"]], rows
            print("two postgres containers answered on ports", sorted(ports))
      '';

      containersProbe = pkgs.harasPackages.makePodmanScript {
        name = "containers-probe";
        images = [ probeImage ];
        text = ''
          image=localhost/container-probe:latest

          driver="$(podman --remote info --format '{{.Store.GraphDriverName}}')"
          test "$driver" = overlay

          greeting="$(podman --remote run --rm "$image")"
          test "$greeting" = "hello from the container"

          user="$(podman --remote run --rm --user 999:999 "$image" /bin/id -u)"
          test "$user" = 999

          for port in ${lib.concatMapStringsSep " " builtins.toString ports}; do
            podman --remote run --detach --rm --publish "$port:80" \
              "$image" /bin/httpd -f -p 80 > /dev/null
          done

          for port in ${lib.concatMapStringsSep " " builtins.toString ports}; do
            # shellcheck disable=SC2016
            timeout ${builtins.toString connectTimeout} bash -c \
              'until (exec 3<>/dev/tcp/127.0.0.1/"$1") 2> /dev/null; do sleep 0.1; done' \
              _ "$port"
          done
        '';
      };

      outsideProbe = pkgs.harasPackages.makePodmanScript {
        name = "outside-probe";
        text = ''
          test -z "''${CONTAINER_HOST:-}"
          touch "$1"
        '';
      };

      noFeatureProbe = pkgs.harasPackages.makePodmanScript {
        name = "no-feature-probe";
        text = "true";
      };
    in
    {
      checks = lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
        podman-script =
          pkgs.runCommand "haraspkgs-podman-script-check"
            {
              requiredSystemFeatures = [ "uid-range" ];
            }
            ''
              ${lib.getExe containersProbe}
              touch "$out"
            '';

        podman-hook = pkgs.harasPackages.withPodman (
          pkgs.runCommand "haraspkgs-podman-hook-check"
            {
              nativeBuildInputs = [ python ];
              podmanImages = [ pkgs.harasPackages.image-postgresql-18 ];
            }
            ''
              python ${postgresScript}
              touch "$out"
            ''
        );

        podman-outside-sandbox = pkgs.runCommand "haraspkgs-podman-outside-sandbox-check" { } ''
          env --unset=NIX_BUILD_TOP ${lib.getExe outsideProbe} "$out"
        '';

        podman-without-uid-range = pkgs.runCommand "haraspkgs-podman-without-uid-range-check" { } ''
          if output="$(${lib.getExe noFeatureProbe} 2>&1)"; then
            echo "the script started in a build without uid-range" >&2
            exit 1
          fi
          grep --fixed-strings uid-range <<< "$output"
          touch "$out"
        '';
      };
    };
}
