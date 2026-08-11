function fish_bind_count
    argparse h/help z/zero r/read b/backspace -- $argv
    or return 1
    if test -n "$_flag_help"
        echo "Helper function to track count modifier with modal key bindings"
        echo "Usage: $0 [-h] [-z] [-r] [-b] [DIGITS ...]"
        return
    end
    set -l count_defined false
    if string match -rq '^[1-9]\d*$' "$fish_bind_count"
        set count_defined true
    end

    if test -n "$_flag_backspace"
        if test $count_defined = false
            return 1
        end

        set -l length (string length -- "$fish_bind_count")
        if test $length -le 1
            set -g fish_bind_count 0
        else
            set -g fish_bind_count (string sub --start 1 --length (math $length - 1) -- "$fish_bind_count")
        end
        return
    end

    if test -n "$_flag_zero" || test $count_defined = false
        set -g fish_bind_count 0
    end
    # Iterate over given digits
    for arg in $argv
        for digit in (string split '' "$arg")
            if test "$fish_bind_count" = 0
                set -g fish_bind_count "$digit"
            else
                set -g fish_bind_count "$fish_bind_count$digit"
            end
        end
    end
    if test -n "$_flag_read"
        set -l count "$fish_bind_count"
        set -g fish_bind_count 0
        if test "$count" = 0
            echo 1
            return 1
        else
            echo "$count"
        end
    end
end
