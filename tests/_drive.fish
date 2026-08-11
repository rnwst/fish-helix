set temp_dir "$argv[1]"
set tmux tmux -f /dev/null -S "$temp_dir/tmux"
set actions (string split0 <"$temp_dir/actions")

# Wait until the test shell has returned from its startup commands.
sleep 0.1

for index in (seq 1 2 (count $actions))
    if test "$actions[$index]" = check
        $tmux send-keys F9
        sleep 0.1
        continue
    end

    set value_index (math $index + 1)
    set sequence "$actions[$value_index]"
    switch "$sequence"
        case Normal
            $tmux send-keys F11
            sleep 0.1
        case Line
            $tmux send-keys F11
            sleep 0.1
            $tmux send-keys -l o
            sleep 0.1
        case Escape
            $tmux send-keys -H 1b
            sleep 0.1
        case Enter
            $tmux send-keys -H 0d
            sleep 0.1
        case Backspace
            $tmux send-keys -H 7f
            sleep 0.1
        case Ctrl-a
            $tmux send-keys C-a
            sleep 0.1
        case Ctrl-x
            $tmux send-keys C-x
            sleep 0.1
        case Alt-colon
            $tmux send-keys M-:
            sleep 0.1
        case Alt-period
            $tmux send-keys M-.
            sleep 0.1
        case Alt-backtick
            $tmux send-keys M-\`
            sleep 0.1
        case Pause
            sleep 0.5
        case t-enter
            $tmux send-keys -l t
            sleep 0.1
            $tmux send-keys -H 0d
            sleep 0.1
        case f-enter
            $tmux send-keys -l f
            sleep 0.1
            $tmux send-keys -H 0d
            sleep 0.05
        case T-enter
            $tmux send-keys -l T
            sleep 0.1
            $tmux send-keys -H 0d
            sleep 0.05
        case F-enter
            $tmux send-keys -l F
            sleep 0.1
            $tmux send-keys -H 0d
            sleep 0.05
        case '*'
            if string match -qr '[^[:ascii:]]' -- "$sequence"
                $tmux send-keys -l -- "$sequence"
                sleep 0.1
            else
                for char in (string split '' -- "$sequence")
                    if test "$char" = ";"
                        $tmux send-keys -H 3b
                    else
                        $tmux send-keys -l -- "$char"
                    end
                    sleep 0.1
                end
            end
    end
end

$tmux send-keys F12
