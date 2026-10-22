{
  self.lib.containers = {
    nspawnModule =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        cfg = config.virtualisation;
        name = config.system.name;

        envFile = if cfg.environmentFile != null then cfg.environmentFile else pkgs.emptyFile;
      in
      {
        options.virtualisation = {
          cmdline = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Arguments passed to the container init after the init path.";
          };

          rootDir = lib.mkOption {
            type = lib.types.str;
            default = "/var/lib/haraspkgs-containers/${name}/root";
            description = "Writable root directory for the systemd-nspawn container.";
          };

          stateDir = lib.mkOption {
            type = lib.types.str;
            default = "/var/lib/haraspkgs-containers/${name}/state";
            description = "Host directory bound to /var/lib/haraspkgs inside the container.";
          };

          environmentFile = lib.mkOption {
            type = lib.types.nullOr lib.types.path;
            default = null;
            description = "Host environment file bound to /run/haraspkgs.env inside the container.";
          };

          systemd-nspawn = {
            package = lib.mkPackageOption pkgs "systemd" { };

            options = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "Arguments passed to systemd-nspawn.";
            };
          };
        };

        config = {
          boot.isNspawnContainer = true;
          console.enable = true;

          services.journald.console = "/dev/console";

          virtualisation.systemd-nspawn.options = [
            "--quiet"
            "--machine=${name}"
            "--console=read-only"
            "--notify-ready=yes"
            "--kill-signal=SIGRTMIN+3"
            "--bind-ro=/nix/store:/nix/store"
            "--bind-ro=/nix/var/nix/db:/nix/var/nix/db"
            "--bind-ro=/nix/var/nix/daemon-socket:/nix/var/nix/daemon-socket"
            "--background="
          ];

          systemd.services.console-getty.enable = false;

          services.openssh = {
            enable = true;
            settings = {
              PermitRootLogin = "yes";
              PermitEmptyPasswords = "yes";
              UsePAM = false;
            };
          };
          users.users.root.hashedPasswordFile = "${pkgs.writeText "haraspkgs-root-hashed-password" ""}";

          systemd.services.sshd.enable = false;

          system.build.nspawn = pkgs.writeShellApplication {
            name = "run-nspawn";
            runtimeInputs = [
              pkgs.coreutils
              cfg.systemd-nspawn.package
            ];
            text = ''
              root_dir=${lib.escapeShellArg cfg.rootDir}
              state_dir=${lib.escapeShellArg cfg.stateDir}
              env_file=${lib.escapeShellArg envFile}

              case "''${1:-}" in
                --env-file)
                  env_file="$2"
                  shift 2
                  ;;
                --env-file=*)
                  env_file="''${1#--env-file=}"
                  shift
                  ;;
                --root-dir)
                  root_dir="$2"
                  shift 2
                  ;;
                --root-dir=*)
                  root_dir="''${1#--root-dir=}"
                  shift
                  ;;
                --state-dir)
                  state_dir="$2"
                  shift 2
                  ;;
                --state-dir=*)
                  state_dir="''${1#--state-dir=}"
                  shift
                  ;;
              esac

              base_dir="$(dirname "$root_dir")"

              mkdir -p "$root_dir/usr/bin"
              chmod 0755 "$root_dir" "$root_dir/usr/bin"
              mkdir -p "$state_dir" "$base_dir/nix/profiles" "$base_dir/nix/gcroots"

              sudo umount -R "/run/systemd/nspawn/unix-export/${name}" 2>/dev/null || true
              sudo rm -rf "/run/systemd/nspawn/unix-export/${name}"

              exec systemd-nspawn \
                ${lib.escapeShellArgs cfg.systemd-nspawn.options} \
                --directory="$root_dir" \
                --bind="$base_dir/nix/profiles:/nix/var/nix/profiles" \
                --bind="$base_dir/nix/gcroots:/nix/var/nix/gcroots" \
                --bind="$state_dir:/var/lib/haraspkgs" \
                --bind-ro="$env_file:/run/haraspkgs.env" \
                "$@" \
                "${config.system.build.toplevel}/init" ${lib.escapeShellArgs cfg.cmdline}
            '';
          };
        };
      };
  };
}
