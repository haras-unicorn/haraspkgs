{
  self.devTests.gitleaks = {
    flake = true;
    value = {
      modules = [
        ({ pkgs, ... }: {
          gitleaks = {
            enable = pkgs.stdenv.isLinux;
            settings.title = "example";
          };
        })
      ];
      commands = [
        ''if [ "$(uname)" = Linux ]; then command -v dev-gitleaks; dev-gitleaks version; dev --help | grep -q 'hook-pre-commit'; dev --help | grep -q 'check'; fi''
      ];
    };
  };
}
