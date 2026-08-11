set -g fish_escape_delay_ms 30
set test_root (dirname (status filename))
set q_action
set q_value

function _deferred_tmux
    begin
        for index in (seq (count $q_action))
            printf '%s\0%s\0' "$q_action[$index]" "$q_value[$index]"
        end
    end >"$temp_dir/actions"

    set fish_path (string escape -- (command -s fish))
    set driver_path (string escape -- "$test_root/_drive.fish")
    set temp_path (string escape -- "$temp_dir")
    command tmux -f /dev/null run-shell -b "$fish_path $driver_path $temp_path"
end

set tmux _deferred_tmux

function push_check -a property
    set expected $argv[2..-1]
    set broken ""
    if test _"$expected[1]" = _--broken
        set broken yes
        set expected $expected[2..-1]
    end
    set -a q_property "$property"
    set -a q_broken "$broken"
    set -a q_expected "$expected"
    set -a q_action check
    set -a q_value _
end

function _input
    for sequence in $argv
        set -a q_action input
        set -a q_value "$sequence"
    end
end
