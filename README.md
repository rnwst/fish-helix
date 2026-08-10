# fish-helix

Helix-like key bindings for the fish command line.

# Installation

Dependencies: fish >= 4.0, perl, and common GNU tools.

Tested with fish 4.8.1.

1. Copy `functions` directory as `~/.config/fish/functions`.
2. Run `fish_helix_key_bindings`.

## Compatibility

The current branch targets fish 4.x. Older fish 3.x versions are not supported here.

If you need fish 3.x support, use an older release or branch.

## Revert

To go back to fish's default bindings, run:

```fish
fish_default_key_bindings
```

# Tests

Install the test dependencies:

- `tmux`
- `inotify-tools`
- `perl`
- fish 4.x

Then run:

```fish
./run-tests
```

The tests drive an interactive fish shell through tmux. They send keys with short pauses so fish has time to update the command line between checks.

# Configuration

`fish_helix_command` function provides some helix-like actions. Use it for custom bindings.

Example:

```fish
bind --user -M default x "fish_helix_command select_line"
```

# Supported Keys

This is a Helix-like keymap for fish's command line. It is not a full Helix editor inside fish.

Normal and select mode support includes:

- Modes: `Escape`, `v`, `i`, `a`, `I`, `A`, `o`, `O`
- Motions: `h`, `j`, `k`, `l`, arrows, `w`, `b`, `e`, `W`, `B`, `E`, `f`, `F`, `t`, `T`, `Alt-.`
- Goto: `gh`, `gl`, `gs`, `gg`, `ge`, `G`, `Home`, `End`
- Changes: `r`, `~`, `` ` ``, `` Alt-` ``, `u`, `U`, `d`, `Alt-d`, `c`, `Alt-c`, `y`, `p`, `P`, `R`
- Selection: `x`, `X`, `Alt-x`, `%`, `;`, `Alt-;`, `J`, `mm`
- Clipboard: `Space-y`, `Space-p`, `Space-P`, `Space-R`

## Known Limits

Some Helix features do not fit well in a shell prompt and are not implemented:

- Multiple selections
- LSP and tree-sitter features
- Windows and pickers
- Registers and macros
- Most shell/filter commands from Helix

## Custom Binding Notes

When defining your own bindings using fish_helix_command, be aware that it can break
stuff sometimes.

It is safe to define a binding consisting of a lone call to fish_helix_command.
Calls to other functions and executables are allowed along with it, granted they don't mess
with fish's commandline buffer.

Mixing multiple fish_helix_commandline and commandline calls in one binding MAY trigger issues.
Nothing serious, but don't be surprised. Just test it.
