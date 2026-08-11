# fish-helix

[Helix](https://helix-editor.com/)-like key bindings for the [fish shell](https://fishshell.com/).

## Installation

Dependencies: fish >= 4.0, perl, and common GNU tools.

Tested with fish 4.8.1.

1. Clone the repository:

   ```fish
   git clone https://github.com/rnwst/fish-helix.git ~/.config/fish/fish-helix
   ```

2. Symlink the provided functions into Fish's function directory:

   ```fish
   mkdir -p ~/.config/fish/functions
   for function_file in ~/.config/fish/fish-helix/functions/*.fish
       ln -s "$function_file" ~/.config/fish/functions/
   end
   ```

3. Enable the bindings. Run `fish_helix_key_bindings` directly for the
   current session, or add it to `~/.config/fish/config.fish` to enable the
   bindings whenever Fish starts:

   ```fish
   fish_helix_key_bindings
   ```

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
- `fish` (4.x)

Then run:

```fish
./run-tests
```

Pass `--verbose` to print each test file as it runs.

The tests drive an interactive fish shell through tmux. They send keys with short pauses so fish has time to update the command line between checks.

# Configuration

`fish_helix_command` function provides some helix-like actions. Use it for custom bindings.

Example:

```fish
bind --user -M default x "fish_helix_command select_line"
```

On fish 4, input functions execute synchronously, so a binding can compose multiple actions:

```fish
bind --user -M default z "fish_helix_command goto_line_start goto_line_end"
```

All digits are count prefixes by default, including `0`. To use `0` to move to line-start (like in vim) while retaining it inside counts such as `10`, add this user binding after enabling fish-helix:

```fish
for mode in default visual
    bind --user -M $mode 0 '
        if string match -rq "^[1-9][0-9]*$" "$fish_bind_count"
            fish_bind_count 0
        else
            fish_helix_command goto_line_start
        end
    '
end
```

# Supported Keys

This is a Helix-like keymap for fish's command line. It is not a full Helix editor inside fish.

Normal and select mode support includes:

- Modes: `Escape`, `v`, `i`, `a`, `I`, `A`, `o`, `O`
- Motions: `h`, `j`, `k`, `l`, arrows, `w`, `b`, `e`, `W`, `B`, `E`, `f`, `F`, `t`, `T`, `Alt-.`
- Goto: `gh`, `gl`, `gs`, `gg`, `ge`, `G`, `Home`, `End`
- Counts: `0`-`9`; `Backspace` removes the last pending digit and `Escape` clears the count
- Changes: `r`, `~`, `` ` ``, `` Alt-` ``, `Ctrl-a`, `Ctrl-x`, `u`, `U`, `d`, `Alt-d`, `c`, `Alt-c`, `y`, `p`, `P`, `R`
- Selection: `x`, `X`, `Alt-x`, `%`, `;`, `Alt-;`, `Alt-:`, `_`, `J`, `mm`
- Clipboard: `Space-y`, `Space-p`, `Space-P`, `Space-R`

In Normal and select mode, `Ctrl-a` increments a decimal number and `Ctrl-x` decrements it. Insert mode retains fish's shared `Ctrl-x` clipboard-copy binding.

## Known Limits

Some Helix features do not fit well in a shell prompt and are not implemented:

- Multiple selections
- LSP and tree-sitter features
- Windows and pickers
- Registers and macros
- Most shell/filter commands from Helix
- Editor-specific indentation, formatting, search, and unimpaired motions (`[p`, `]p`, `[<Space>`, ...)

Insert mode otherwise keeps fish's shell-oriented bindings for completion, autosuggestions, clipboard access, and word deletion. `Ctrl-c` also remains command-line cancellation rather than Helix's comment command.
