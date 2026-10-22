{ lib, ... }:

{
  self.lib.dev = {
    commands =
      let
        normalizeCommand = value: if builtins.isString value then { text = value; } else value;
      in
      lib.mkOptionType {
        name = "commands";
        description = "A bash command or list of commands, as strings or attrsets with a text field.";
        descriptionClass = "noun";
        check =
          let
            oneCheck =
              value:
              builtins.isString value || (builtins.isAttrs value && value ? text && builtins.isString value.text);
          in
          value: oneCheck value || (builtins.isList value && builtins.all oneCheck value);
        merge =
          _loc: defs: builtins.map normalizeCommand (lib.flatten (builtins.map (def: def.value) defs));
      };

    concatCommands =
      commands:
      let
        # NOTE: this preserves string context unlike lib.trim
        trim =
          text:
          let
            length = builtins.stringLength text;
            leadingMatch = builtins.match "[[:space:]]*(.*)" text;
            leading = length - builtins.stringLength (builtins.head leadingMatch);
            contentMatch = builtins.match "(.*[^[:space:]])[[:space:]]*" text;
          in
          if contentMatch == null then
            ""
          else
            let
              end = builtins.stringLength (builtins.head contentMatch);
            in
            builtins.substring leading (end - leading) text;
      in
      lib.concatMapStringsSep "\n"
        (
          command:
          let
            commandText = trim (
              if builtins.isString command then
                command
              else if builtins.isAttrs command && command ? text && builtins.isString command.text then
                command.text
              else
                ""
            );
            commandDepth =
              if builtins.isAttrs command && command ? depth && builtins.isInt command.depth then
                command.depth
              else
                1;
            commandPrompt =
              if builtins.isAttrs command && command ? prompt && builtins.isString command.prompt then
                command.prompt
              else
                lib.strings.replicate commandDepth ">";
            commandHeader = lib.trim (
              if builtins.isAttrs command && command ? header && builtins.isString command.header then
                "${commandPrompt} ${command.header}"
              else
                builtins.concatStringsSep "\n" (
                  builtins.map (line: "${commandPrompt} ${line}") (
                    builtins.filter builtins.isString (builtins.split "\n" commandText)
                  )
                )
            );
          in
          ''
            # shellcheck disable=SC2016
            printf "%s\n\n" ${lib.escapeShellArg commandHeader} >&2
            ${commandText}
            printf "\n" >&2
          ''
        )
        (
          builtins.filter (
            command:
            (builtins.isString command && command != "")
            || (
              builtins.isAttrs command && command ? text && builtins.isString command.text && command.text != ""
            )
          ) commands
        );

    extractPassthruDevShellAttrs =
      devShells: attr: filter:
      builtins.listToAttrs (
        builtins.concatMap (
          { name, value }:
          lib.mapAttrsToList (inner: value: {
            inherit value;
            name = "${name}-${inner}";
          }) (lib.filterAttrs (_: filter) (value.passthru.${attr} or { }))
        ) (lib.attrsToList devShells)
      );
  };
}
