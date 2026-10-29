{ lib, ... }:

{
  # Flattens flake inputs and all of their transitive inputs into one attrset
  # keyed by input path (`a`, `a/b`, `a/b/c`, ...), which is the key format of
  # `--override-input`. Flake input graphs are finite, so this goes as deep as
  # the hierarchy does.
  self.lib.flattenInputs =
    let
      flatten = lib.concatMapAttrs (
        name: input:
        {
          ${name} = input;
        }
        // lib.mapAttrs' (nested: lib.nameValuePair "${name}/${nested}") (
          if input ? inputs then flatten input.inputs else { }
        )
      );
    in
    flatten;
}
