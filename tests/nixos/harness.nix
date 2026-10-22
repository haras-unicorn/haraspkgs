{
  ...
}:

{
  self.nixosTests.harness = {
    flake = true;

    value = _: {
      globalTimeout = 600;

      containers.agent = {
        environment.etc."haraspkgs/harness".text = "harness";
      };

      testScript = ''
        start_all()
        agent.succeed("grep -qx harness /etc/haraspkgs/harness")
      '';
    };
  };
}
