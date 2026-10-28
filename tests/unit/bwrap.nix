{
  selfLib,
  ...
}:

let
  inherit (selfLib) bwrap;

  contains = args: builtins.elem args;

  hasAll = args: builtins.all (arg: contains arg args);
in
{
  self.unitTests.bwrap = {
    test-local-unshares = {
      expr = contains "--unshare-all" bwrap.local;
      expected = true;
    };

    test-local-has-no-network = {
      expr = contains "--share-net" bwrap.local;
      expected = false;
    };

    test-local-has-no-network-files = {
      expr = builtins.any (arg: contains arg bwrap.local) [
        "/etc/hosts"
        "/etc/nsswitch.conf"
        "/etc/resolv.conf"
        "/etc/ssl"
      ];
      expected = false;
    };

    test-local-has-passwd-and-group = {
      expr = hasAll bwrap.local [
        "/etc/passwd"
        "/etc/group"
      ];
      expected = true;
    };

    test-network-includes-local = {
      expr = hasAll bwrap.network bwrap.local;
      expected = true;
    };

    test-network-shares-network = {
      expr = contains "--share-net" bwrap.network;
      expected = true;
    };

    test-network-has-network-files = {
      expr = hasAll bwrap.network [
        "/etc/hosts"
        "/etc/nsswitch.conf"
        "/etc/resolv.conf"
        "/etc/ssl"
      ];
      expected = true;
    };

    test-network-has-passwd-and-group = {
      expr = hasAll bwrap.network [
        "/etc/passwd"
        "/etc/group"
      ];
      expected = true;
    };
  };
}
