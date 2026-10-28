{
  self.lib.bwrap =
    let
      local = [
        "--die-with-parent"
        "--unshare-all"
        "--ro-bind-try"
        "/nix/store"
        "/nix/store"
        "--ro-bind-try"
        "/usr"
        "/usr"
        "--ro-bind-try"
        "/bin"
        "/bin"
        "--ro-bind-try"
        "/sbin"
        "/sbin"
        "--ro-bind-try"
        "/lib"
        "/lib"
        "--ro-bind-try"
        "/lib64"
        "/lib64"
        "--ro-bind-try"
        "/etc/passwd"
        "/etc/passwd"
        "--ro-bind-try"
        "/etc/group"
        "/etc/group"
        "--tmpfs"
        "/tmp"
        "--proc"
        "/proc"
        "--dev"
        "/dev"
      ];
    in
    {
      inherit local;

      network = local ++ [
        "--share-net"
        "--ro-bind-try"
        "/etc/hosts"
        "/etc/hosts"
        "--ro-bind-try"
        "/etc/nsswitch.conf"
        "/etc/nsswitch.conf"
        "--ro-bind-try"
        "/etc/resolv.conf"
        "/etc/resolv.conf"
        "--ro-bind-try"
        "/etc/ssl"
        "/etc/ssl"
      ];
    };
}
