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

      postgresId = "999";

      passwd = pkgs.writeTextDir "etc/passwd" ''
        root:x:0:0:root:/root:/bin/sh
        postgres:x:${postgresId}:${postgresId}:postgres:/data:/bin/sh
      '';

      group = pkgs.writeTextDir "etc/group" ''
        root:x:0:
        postgres:x:${postgresId}:
      '';

      postgresServer = pkgs.writeShellApplication {
        name = "postgres-server";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.postgresql
        ];
        text = ''
          initdb --pgdata /data --username postgres --auth trust \
            --no-locale --encoding UTF8
          # Published ports reach the container from the address of the
          # bridge, which the entries initdb writes do not allow.
          echo "host all all all trust" >> /data/pg_hba.conf
          exec postgres -D /data \
            -c listen_addresses='*' \
            -c unix_socket_directories=/tmp
        '';
      };

      postgresEntrypoint = pkgs.writeShellApplication {
        name = "postgres-entrypoint";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.util-linux
        ];
        text = ''
          mkdir /data
          chown ${postgresId}:${postgresId} /data
          exec setpriv --reuid=${postgresId} --regid=${postgresId} \
            --clear-groups ${lib.getExe postgresServer}
        '';
      };

      postgresImage = pkgs.dockerTools.buildImage {
        name = "postgres-probe";
        tag = "latest";
        copyToRoot = [
          pkgs.dockerTools.binSh
          passwd
          group
          postgresEntrypoint
        ];
        extraCommands = "mkdir -m 1777 tmp";
        # Postgres treats SIGTERM as a smart shutdown that waits for every
        # client to disconnect, and SIGINT as a fast shutdown.
        config = {
          Cmd = [ (lib.getExe postgresEntrypoint) ];
          StopSignal = "SIGINT";
        };
      };

      python = pkgs.python3.withPackages (packages: [
        packages.pg8000
        packages.testcontainers
      ]);

      # The client connects to 127.0.0.1 and not to the name the library
      # reports, because the sandbox has no /etc/hosts to resolve localhost
      # with. Two containers run at once on the same container port, which is
      # what host networking could not do.
      postgresScript = pkgs.writeText "postgres-probe.py" ''
        import subprocess
        import sys

        import pg8000.native
        from testcontainers.core.container import DockerContainer
        from testcontainers.core.wait_strategies import LogMessageWaitStrategy

        subprocess.run(["podman", "--remote", "load", "--input", sys.argv[1]], check=True)


        def postgres():
            container = DockerContainer("localhost/postgres-probe:latest")
            container.with_exposed_ports(5432)
            container.waiting_for(
                LogMessageWaitStrategy("database system is ready to accept connections")
            )
            return container


        def query(container):
            connection = pg8000.native.Connection(
                user="postgres",
                host="127.0.0.1",
                port=int(container.get_exposed_port(5432)),
                database="postgres",
            )
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
        text = ''
          image=localhost/container-probe:latest

          podman --remote load --input ${probeImage} > /dev/null

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
            }
            ''
              python ${postgresScript} ${postgresImage}
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
