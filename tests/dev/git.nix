{
  self.devTests.git = {
    flake = true;
    value = {
      modules = [
        {
          git = {
            enable = true;
            ignore.patterns = "*.log";
            ignore.templates = [ "Nix" ];
            attributes = "*.nix text";
          };
        }
      ];
      commands = [
        "grep -qx '\\*.log' .gitignore"
        "grep -q '# github/gitignore: Nix.gitignore' .gitignore"
        "grep -qx '\\*.nix text' .gitattributes"
        "git --version"
        "! dev --help | grep -q 'hook-'"
      ];
    };
  };

  self.devTests.git-hooks = {
    flake = true;
    value = {
      modules = [
        ({ pkgs, lib, ... }: {
          git = {
            enable = true;
            hooks = lib.optionalAttrs pkgs.stdenv.isLinux {
              pre-commit.commands = "printf hook > hook.txt";
            };
          };
        })
      ];
      commands = [
        ''if [ "$(uname)" = Linux ]; then dev hook-pre-commit; test "$(cat hook.txt)" = hook; grep -q GIT_CONFIG_KEY_0 "$(command -v git)"; fi''
      ];
    };
  };
}
