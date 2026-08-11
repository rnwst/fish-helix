# IMPORTANT!!!
#
# When defining your own bindings using fish_helix_command, be aware that it can break
# stuff sometimes.
#
# It is safe to define a binding consisting of a lone call to fish_helix_command.
# Calls to other functions and executables are allowed along with it, granted they don't mess
# with fish's commandline buffer.
#
# Mixing multiple fish_helix_commandline and commandline calls in one binding MAY trigger issues.
# Nothing serious, but don't be surprised. Just test it.

function fish_helix_key_bindings --description 'helix-like key bindings for fish'
    if contains -- -h $argv
        or contains -- --help $argv
        echo "Sorry but this function doesn't support -h or --help"
        return 1
    end

    # Erase all bindings if not explicitly requested otherwise to
    # allow for hybrid bindings.
    # This needs to be checked here because if we are called again
    # via the variable handler the argument will be gone.
    set -l rebind true
    if test "$argv[1]" = --no-erase
        set rebind false
        set -e argv[1]
    else
        bind --erase --all --preset # clear earlier bindings, if any
    end

    # Allow just calling this function to correctly set the bindings.
    # Because it's a rather discoverable name, users will execute it
    # and without this would then have subtly broken bindings.
    if test "$fish_key_bindings" != fish_helix_key_bindings
        and test "$rebind" = true
        __fish_change_key_bindings fish_helix_key_bindings
    end

    set -l init_mode insert

    if contains -- $argv[1] insert default visual
        set init_mode $argv[1]
    else if set -q argv[1]
        # We should still go on so the bindings still get set.
        echo "Unknown argument $argv" >&2
    end

    function __fish_helix_key_bindings_shared
        eval "$(__fish_shared_key_bindings)"
    end

    # Inherit shared key bindings.
    # Do this first so helix-bindings win over default.
    for mode in insert default visual
        __fish_helix_key_bindings_shared -M $mode
    end
    functions -e __fish_helix_key_bindings_shared

    bind -s --preset -M insert enter execute

    bind -s --preset -M insert "" self-insert

    # Space and other command terminators expand abbrs _and_ inserts itself.
    bind -s --preset -M insert " " self-insert expand-abbr
    bind -s --preset -M insert ";" self-insert expand-abbr
    bind -s --preset -M insert "|" self-insert expand-abbr
    bind -s --preset -M insert "&" self-insert expand-abbr
    bind -s --preset -M insert "^" self-insert expand-abbr
    bind -s --preset -M insert ">" self-insert expand-abbr
    bind -s --preset -M insert "<" self-insert expand-abbr
    # Closing a command substitution expands abbreviations
    bind -s --preset -M insert ")" self-insert expand-abbr
    # Ctrl-space inserts space without expanding abbrs
    bind -s --preset -M insert ctrl-space 'commandline -i " "'

    # Switching to insert mode
    for mode in default visual
        bind -s --preset -M $mode -m insert ctrl-c end-selection cancel-commandline repaint-mode
        bind -s --preset -M $mode -m insert enter end-selection execute
        bind -s --preset -M $mode -m insert o end-selection insert-line-under repaint-mode
        bind -s --preset -M $mode -m insert O end-selection insert-line-over repaint-mode
        # FIXME i/a should keep selection, maybe
        bind -s --preset -M $mode i "fish_helix_command insert_mode"
        bind -s --preset -M $mode I "fish_helix_command prepend_to_line"
        bind -s --preset -M $mode a "fish_helix_command append_mode"
        bind -s --preset -M $mode A "fish_helix_command append_to_line"
    end

    # Switching from insert mode
    # Note if we are paging, we want to stay in insert mode
    # See #2871
    bind -s --preset -M insert escape "if commandline -P; commandline -f cancel; else; set fish_bind_mode default; commandline -f begin-selection repaint-mode; end"

    # Switching between normal and visual mode
    bind -s --preset -M default -m visual v repaint-mode
    for key in v escape
        bind -s --preset -M visual -m default $key repaint-mode
    end

    # Motion and actions in normal/select mode
    for mode in default visual
        if test $mode = default
            set -f n_begin_selection begin-selection # only begin-selection if current mode is Normal
            set -f ns_move_extend move
            set -f commandline_v_repaint ""
        else
            set -f n_begin_selection
            set -f ns_move_extend extend
            set -f commandline_v_repaint "commandline -f repaint-mode"
        end

        for key in (seq 0 9)
            bind -s --preset -M $mode $key "fish_bind_count $key"
            # FIXME example to bind 0
            # FIXME backspace to edit count
        end
        for key in h left
            bind -s --preset -M $mode $key "fish_helix_command "$ns_move_extend"_char_left"
        end
        for key in l right
            bind -s --preset -M $mode $key "fish_helix_command "$ns_move_extend"_char_right"
        end
        for key in k up
            bind -s --preset -M $mode $key "fish_helix_command char_up"
        end
        for key in j down
            bind -s --preset -M $mode $key "fish_helix_command char_down"
        end

        bind -s --preset -M $mode w "fish_helix_command next_word_start"
        bind -s --preset -M $mode b "fish_helix_command prev_word_start"
        bind -s --preset -M $mode e "fish_helix_command next_word_end"
        bind -s --preset -M $mode W "fish_helix_command next_long_word_start"
        bind -s --preset -M $mode B "fish_helix_command prev_long_word_start"
        bind -s --preset -M $mode E "fish_helix_command next_long_word_end"

        bind -s --preset -M $mode t "fish_helix_command till_next_char"
        bind -s --preset -M $mode f "fish_helix_command find_next_char"
        bind -s --preset -M $mode T "fish_helix_command till_prev_char"
        bind -s --preset -M $mode F "fish_helix_command find_prev_char"

        for key in g,h home
            bind -s --preset -M $mode $key "fish_helix_command goto_line_start"
        end
        for key in g,l end
            bind -s --preset -M $mode $key "fish_helix_command goto_line_end"
        end
        bind -s --preset -M $mode g,s "fish_helix_command goto_first_nonwhitespace"
        bind -s --preset -M $mode g,g "fish_helix_command goto_file_start"
        bind -s --preset -M $mode G "fish_helix_command goto_line"
        bind -s --preset -M $mode g,e "fish_helix_command goto_last_line"

        bind -s --preset -M $mode escape,. "fish_helix_command repeat_last_motion"

        # FIXME reselect after undo/redo
        bind -s --preset -M $mode u undo begin-selection
        bind -s --preset -M $mode U redo begin-selection

        bind -s --preset -M $mode -m replace_one r repaint-mode

        # FIXME registers
        # bind -s --preset -M $mode y fish_clipboard_copy
        # bind -s --preset -M $mode P fish_clipboard_paste
        # bind -s --preset -M $mode R kill-selection begin-selection yank-pop yank

        bind -s --preset -M $mode -m default d "fish_helix_command delete_selection; $commandline_v_repaint"
        bind -s --preset -M $mode -m default escape,d "fish_helix_command delete_selection_noyank; $commandline_v_repaint"
        bind -s --preset -M $mode -m insert c "fish_helix_command delete_selection; commandline -f end-selection repaint-mode"
        bind -s --preset -M $mode -m insert escape,c "fish_helix_command delete_selection_noyank; commandline -f end-selection repaint-mode"

        bind -s --preset -M $mode -m default y "fish_helix_command yank"
        bind -s --preset -M $mode p "fish_helix_command paste_after"
        bind -s --preset -M $mode P "fish_helix_command paste_before"
        bind -s --preset -M $mode R "fish_helix_command replace_selection"

        bind -s --preset -M $mode -m default space,y "fish_clipboard_copy; $commandline_v_repaint"
        bind -s --preset -M $mode space,p "fish_helix_command paste_after_clip"
        bind -s --preset -M $mode space,P "fish_helix_command paste_before_clip"
        bind -s --preset -M $mode space,R "fish_helix_command replace_selection_clip"

        bind -s --preset -M $mode "~" togglecase-selection
        bind -s --preset -M $mode "`" downcase-selection
        bind -s --preset -M $mode alt-` upcase-selection

        # FIXME .
        # FIXME < and >
        # FIXME =

        # FIXME \ca \cx
        # FIXME Qq

        ## Shell
        # FIXME

        ## Selection manipulation
        # FIXME & _

        bind -s --preset -M $mode x "fish_helix_command select_line"
        bind -s --preset -M $mode X "fish_helix_command select_line_bounds"
        bind -s --preset -M $mode alt-x "fish_helix_command shrink_to_line_bounds"
        bind -s --preset -M $mode J "fish_helix_command join_lines"

        bind -s --preset -M $mode \; begin-selection
        bind -s --preset -M $mode escape,\; swap-selection-start-stop
        # FIXME \e:

        bind -s --preset -M $mode % "fish_helix_command select_all"

        # FIXME \cc

        ## Search
        # FIXME

        bind -s --preset -M $mode m,m "fish_helix_command match_bracket"

        ## FIXME minor modes: g, m, space

        ## FIXME [ and ] motions
    end

    bind -s --preset -M fish_helix_find_char "" get-key 'fish_helix_command find_char_key "$fish_key"; set -e fish_key'
    bind -s --preset -M fish_helix_find_char enter get-key 'fish_helix_command find_char_key "$fish_key"; set -e fish_key'
    bind -s --preset -M fish_helix_find_char space get-key 'fish_helix_command find_char_key "$fish_key"; set -e fish_key'
    bind -s --preset -M fish_helix_find_char tab get-key 'fish_helix_command find_char_key "$fish_key"; set -e fish_key'
    bind -s --preset -M fish_helix_find_char escape "fish_helix_command cancel_find_char"

    # FIXME should replace the whole selection
    # FIXME should be able to go back to visual mode
    bind -s --preset -M replace_one -m default '' delete-char self-insert backward-char repaint-mode
    bind -s --preset -M replace_one -m default enter 'commandline -f delete-char; commandline -i \n; commandline -f backward-char; commandline -f repaint-mode'
    bind -s --preset -M replace_one -m default escape cancel repaint-mode

    ## FIXME Insert mode keys

    ## Old config from vi:

    # Vi moves the cursor back if, after deleting, it is at EOL.
    # To emulate that, move forward, then backward, which will be a NOP
    # if there is something to move forward to.
    bind -s --preset -M insert delete delete-char forward-single-char backward-char
    bind -s --preset -M default delete delete-char forward-single-char backward-char

    # Backspace deletes a char in insert mode, but not in normal/default mode.
    bind -s --preset -M insert backspace backward-delete-char
    bind -s --preset -M default backspace backward-char
    bind -s --preset -M insert ctrl-h backward-delete-char
    bind -s --preset -M default ctrl-h backward-char
    bind -s --preset -M insert delete delete-char
    bind -s --preset -M default delete delete-char
    # bind -s --preset -M insert shift-delete backward-delete-char # shifted delete
    # bind -s --preset -M default shift-delete backward-delete-char # shifted delete

    #    bind -s --preset '~' togglecase-char forward-single-char
    #    bind -s --preset gu downcase-word
    #    bind -s --preset gU upcase-word
    #
    #    bind -s --preset J end-of-line delete-char
    #    bind -s --preset K 'man (commandline -t) 2>/dev/null; or echo -n \a'
    #

    # same vim 'pasting' note as upper
    bind -s --preset '"*p' forward-char "commandline -i ( xsel -p; echo )[1]"
    bind -s --preset '"*P' "commandline -i ( xsel -p; echo )[1]"

    #
    # visual mode
    #

    # bind -s --preset -M visual -m insert c kill-selection end-selection repaint-mode
    # bind -s --preset -M visual -m insert s kill-selection end-selection repaint-mode
    bind -s --preset -M visual -m default '"*y' "fish_clipboard_copy; commandline -f end-selection repaint-mode"
    bind -s --preset -M visual -m default '~' togglecase-selection end-selection repaint-mode

    # Set the cursor shape
    # After executing once, this will have defined functions listening for the variable.
    # Therefore it needs to be before setting fish_bind_mode.
    fish_vi_cursor
    set -g fish_cursor_selection_mode inclusive

    set fish_bind_mode $init_mode

end
