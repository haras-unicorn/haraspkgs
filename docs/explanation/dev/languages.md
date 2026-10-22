# The language registry

Editor integration needs the same information in several places: which command
starts a server, which arguments it takes, which server belongs to a language,
and whether the language should be formatted automatically. Keeping that in a
registry separate from any editor avoids copying the same mapping into Helix, VS
Code, Marksman, or a future editor module.

## Servers and languages are separate

A server is defined once under `languages.servers`. A language then refers to it
by name. This matters when one server serves several languages or when one
language has multiple servers. It also keeps command details out of the
language-level policy (`auto-format`, formatter choice).

The module deliberately stores no file extensions. Editor modules know their own
matching rules, and formatter modules use `format.formatters` for treefmt
selection. The registry describes intent, not an editor's configuration format.

## Data, not an editor

The registry has no enable flag and no package list. It is inert until an editor
or formatter module reads it. That makes it safe to add to every shell and keeps
the dependency direction simple: editor modules depend on the registry, never
the other way around.

## Related

- [Language registry reference](../../reference/dev/languages.md)
- [Configure languages](../../guides/dev/languages.md)
