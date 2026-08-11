# FIXME this can't be called in sequence in general case,
# because of unsynchronized `commandline -f` and `commandline -C`

function fish_helix_command
    argparse 'h/help' -- $argv
    or return 1
    if test -n "$_flag_help"
        echo "Helper function to handle modal key bindings mostly outside of insert mode"
        return
    end

    # TODO only single command allowed really yet,
    #     because `commandline -f` queues actions, while `commandline -C` is immediate
    for command in $argv
        set -f count (fish_bind_count -r)
        set -f count_defined $status

        switch $command
        case {move,extend}_char_left
            commandline -C (math max\(0, (commandline -C) - $count\))
            __fish_helix_extend_by_command $command
        case {move,extend}_char_right
            commandline -C (math min\((__fish_helix_buffer_length), (commandline -C) + $count\))
            __fish_helix_extend_by_command $command

        case char_up
            __fish_helix_char_up $fish_bind_mode $count
        case char_down
            __fish_helix_char_down $fish_bind_mode $count

        case next_word_start
            # https://regex101.com/r/KXrl1x/1
            set -l regex (string join '' \
            '(?:.?\\n+|' \
            '[[:alnum:]_](?=[^[:alnum:]_\\s])|' \
            '[^[:alnum:]_\\s](?=[[:alnum:]_])|' \
            '[^\\S\\n](?=[\\S\\n])|)' \
            '((?:[[:alnum:]_]+|[^[:alnum:]_\\s]+|)[^\\S\\n]*)' \
            )
            __fish_helix_next_word $fish_bind_mode $count $regex

        case next_long_word_start
            set -l regex (string join '' \
            '(?:.?\\n+|' \
            '[^\\S\\n](?=[\\S\\n])|)' \
            '(\\S*[^\\S\\n]*)' \
            )
            __fish_helix_next_word $fish_bind_mode $count $regex

        case next_word_end
            # https://regex101.com/r/Gl0KP2/1
            set -l regex ' (?:
                .?\\n+ |
                [[:alnum:]_](?=[^[:alnum:]_]) |
                [^[:alnum:]_\\s](?=[[:alnum:]_\\s]) | )
            ( [^\\S\\n]*
                (?: [[:alnum:]_]+ | [^[:alnum:]_\\s]+ | ) ) '
            __fish_helix_next_word $fish_bind_mode $count $regex

        case next_long_word_end
            set -l regex ' (?: .?\\n+ | \\S(?=\\s) | )
            ( [^\\S\\n]* \\S* ) '
            __fish_helix_next_word $fish_bind_mode $count $regex

        case prev_word_start
            set -l regex ' ( (?:
                [[:alnum:]_]+ |
                [^[:alnum:]_\\s]+ | )
            [^\\S\\n]* )
            (?: \\n+.? |
                (?<=[^[:alnum:]_])[[:alnum:]_] |
                (?<=[[:alnum:]_\\s])[^[:alnum:]_\\s] | ) '
            __fish_helix_prev_word $fish_bind_mode $count $regex

        case prev_long_word_start
            set -l regex '
            ( \\S* [^\\S\\n]* )
            (?: \\n+.? | (?<=\\s)\\S | ) '
            __fish_helix_prev_word $fish_bind_mode $count $regex


        case till_next_char
            __fish_helix_prepare_find_char $fish_bind_mode $count forward exclusive
        case find_next_char
            __fish_helix_prepare_find_char $fish_bind_mode $count forward inclusive
        case till_prev_char
            __fish_helix_prepare_find_char $fish_bind_mode $count backward exclusive
        case find_prev_char
            __fish_helix_prepare_find_char $fish_bind_mode $count backward inclusive

        case find_char_key
            __fish_helix_find_char_key $argv[2]
            return
        case cancel_find_char
            __fish_helix_cancel_find_char
        case repeat_last_motion
            __fish_helix_repeat_last_motion $fish_bind_mode $count

        case till_next_cr
            __fish_helix_find_next_cr $fish_bind_mode $count 2
        case find_next_cr
            __fish_helix_find_next_cr $fish_bind_mode $count 1
        case till_prev_cr
            __fish_helix_find_prev_cr $fish_bind_mode $count 1
        case find_prev_cr
            __fish_helix_find_prev_cr $fish_bind_mode $count 0
        case goto_line_start
            commandline -f beginning-of-line
            __fish_helix_extend_by_mode
        case goto_line_end
            __fish_helix_goto_line_end
            __fish_helix_extend_by_mode
        case goto_first_nonwhitespace
            __fish_helix_goto_first_nonwhitespace
            __fish_helix_extend_by_mode

        case goto_file_start
            __fish_helix_goto_line $count
        case goto_line
            if test "$count_defined" = 0 # if true
                __fish_helix_goto_line $count
            end
        case goto_last_line
            commandline -f end-of-buffer beginning-of-line
            __fish_helix_extend_by_mode

        case insert_mode
            commandline -C (commandline -B || commandline -C)
            set fish_bind_mode insert
            commandline -f end-selection repaint-mode

        case append_mode
            commandline -C (commandline -E || commandline -C)
            set fish_bind_mode insert
            commandline -f end-selection repaint-mode

        case prepend_to_line
            __fish_helix_goto_first_nonwhitespace
            set fish_bind_mode insert
            commandline -f end-selection repaint-mode

        case append_to_line
            set fish_bind_mode insert
            commandline -f end-selection end-of-line repaint-mode

        case delete_selection
            commandline -f kill-selection begin-selection
        case delete_selection_noyank
            __fish_helix_delete_selection

        case yank
            __fish_helix_yank
        case paste_before
            __fish_helix_paste_before "commandline -f yank"
        case paste_after
            __fish_helix_paste_after "commandline -f yank"
        case replace_selection
            __fish_helix_replace_selection "$fish_killring[1]" "true"

        case paste_before_clip
            __fish_helix_paste_before "fish_clipboard_paste"
        case paste_after_clip
            __fish_helix_paste_after "fish_clipboard_paste" --clip
        case replace_selection_clip
            __fish_helix_replace_selection "" "fish_clipboard_paste" --clip

        case select_line
            __fish_helix_select_line extend
        case select_line_bounds
            __fish_helix_select_line expand
        case shrink_to_line_bounds
            __fish_helix_select_line shrink
        case join_lines
            __fish_helix_join_lines
        case match_bracket
            commandline -f jump-to-matching-bracket
            __fish_helix_extend_by_mode
        case select_all
            commandline -f beginning-of-buffer begin-selection end-of-buffer end-of-line backward-char


        case '*'
            echo "[fish-helix]" Unknown command $command >&2
        end
    end
end

function __fish_helix_extend_by_command -a piece
    if not string match -qr extend_ $piece
        commandline -f begin-selection
    end
end

function __fish_helix_extend_by_mode
    if test $fish_bind_mode = default
        commandline -f begin-selection
    end
end

function __fish_helix_prepare_find_char -a mode count direction inclusive
    set -g __fish_helix_find_char_mode $mode
    set -g __fish_helix_find_char_count $count
    set -g __fish_helix_find_char_direction $direction
    set -g __fish_helix_find_char_inclusive $inclusive
    set fish_bind_mode fish_helix_find_char
    commandline -f repaint-mode
end

function __fish_helix_find_char_key -a key
    set -l mode $__fish_helix_find_char_mode
    set -l count $__fish_helix_find_char_count
    set -l direction $__fish_helix_find_char_direction
    set -l inclusive $__fish_helix_find_char_inclusive

    __fish_helix_clear_pending_find_char
    test -n "$mode"
    or set mode default
    set fish_bind_mode $mode

    if __fish_helix_apply_find_char $mode $count $direction $inclusive "$key"
        set -g __fish_helix_last_find_char_key "$key"
        set -g __fish_helix_last_find_char_direction $direction
        set -g __fish_helix_last_find_char_inclusive $inclusive
    end
    commandline -f repaint-mode
end

function __fish_helix_cancel_find_char
    set -l mode $__fish_helix_find_char_mode
    __fish_helix_clear_pending_find_char
    test -n "$mode"
    or set mode default
    set fish_bind_mode $mode
    commandline -f repaint-mode
end

function __fish_helix_clear_pending_find_char
    set -e __fish_helix_find_char_mode
    set -e __fish_helix_find_char_count
    set -e __fish_helix_find_char_direction
    set -e __fish_helix_find_char_inclusive
end

function __fish_helix_repeat_last_motion -a mode count
    test -n "$__fish_helix_last_find_char_key"
    or return
    __fish_helix_apply_find_char $mode $count $__fish_helix_last_find_char_direction $__fish_helix_last_find_char_inclusive "$__fish_helix_last_find_char_key"
end

function __fish_helix_apply_find_char -a mode count direction inclusive key
    set -l cursor (commandline -C)
    commandline --current-buffer |
    perl -CS -Mutf8 -e '
        use open qw(:std :utf8);
        my ($direction, $inclusive, $count, $cursor, $key) = @ARGV;
        my $buffer = do { local $/; <STDIN> };
        chomp $buffer;
        my @chars = split //, $buffer;
        my $length = scalar @chars;
        my $seen = 0;
        my $found;

        if ($direction eq "forward") {
            my $start = $cursor + ($inclusive eq "inclusive" ? 1 : 2);
            for (my $i = $start; $i < $length; $i++) {
                next unless $chars[$i] eq $key;
                $seen++;
                if ($seen == $count) {
                    $found = $i;
                    last;
                }
            }
            $found-- if defined $found && $inclusive ne "inclusive";
        } else {
            my $start = $cursor + ($inclusive eq "inclusive" ? 0 : -1);
            $start = $length - 1 if $start >= $length;
            for (my $i = $start; $i >= 0; $i--) {
                next unless $chars[$i] eq $key;
                $seen++;
                if ($seen == $count) {
                    $found = $i;
                    last;
                }
            }
            $found++ if defined $found && $inclusive ne "inclusive";
        }

        exit 1 unless defined $found && $found >= 0 && $found < $length;
        print $found;
    ' $direction $inclusive $count $cursor "$key" |
    read -l target
    or return 1

    if test $mode = visual
        set -l start (commandline -B)
        set -l end (commandline -E)
        set -l anchor $start
        if test -n "$start" -a -n "$end" -a "$cursor" = "$start"
            set anchor (math $end - 1)
        end

        if test $target -lt $anchor
            __fish_helix_select_range $target (math $anchor + 1) left
        else
            __fish_helix_select_range $anchor (math $target + 1) right
        end
    else
        if test $direction = backward
            __fish_helix_select_range $target (math $cursor + 1) left
        else
            __fish_helix_select_range $cursor (math $target + 1) right
        end
    end
end

function __fish_helix_buffer_length
    commandline --current-buffer |
    perl -CS -Mutf8 -e 'use open qw(:std :utf8); my $buffer = do { local $/; <STDIN> }; chomp $buffer; print length $buffer'
end

function __fish_helix_select_range -a start end cursor_side
    set -l length (commandline --current-buffer |
    perl -CS -Mutf8 -e 'use open qw(:std :utf8); my $buffer = do { local $/; <STDIN> }; chomp $buffer; print length $buffer')
    if test $start -lt 0
        set start 0
    else if test $start -gt $length
        set start $length
    end
    if test $end -lt 0
        set end 0
    else if test $end -gt $length
        set end $length
    end

    commandline -f end-selection

    if test $end -le $start
        commandline -C $start
        commandline -f begin-selection
        return
    end

    if test "$cursor_side" = left
        commandline -C (math $end - 1)
        commandline -f begin-selection
        for i in (seq 1 (math $end - $start - 1))
            commandline -f backward-char
        end
    else
        commandline -C $start
        commandline -f begin-selection
        for i in (seq 1 (math $end - $start - 1))
            commandline -f forward-char
        end
    end
end

function __fish_helix_select_line -a action
    commandline --current-buffer |
    perl -CS -Mutf8 -e '
        use open qw(:std :utf8);
        my ($action, $cursor, $selection_start, $selection_end) = @ARGV;
        my $buffer = do { local $/; <STDIN> };
        chomp $buffer;
        my $length = length $buffer;

        sub clamp {
            my ($value) = @_;
            return 0 if $value < 0;
            return $length if $value > $length;
            return $value;
        }

        sub bounds_at {
            my ($pos) = @_;
            $pos = clamp($pos);
            my $search = $pos;
            $search = $length - 1 if $search >= $length && $length > 0;
            my $previous = rindex($buffer, "\n", $search - 1);
            my $start = $previous < 0 ? 0 : $previous + 1;
            my $next = index($buffer, "\n", $search);
            my $end = $next < 0 ? $length : $next + 1;
            return ($start, $end);
        }

        sub is_line_start {
            my ($pos) = @_;
            return $pos == 0 || substr($buffer, $pos - 1, 1) eq "\n";
        }

        sub is_line_end {
            my ($pos) = @_;
            return $pos == $length || ($pos > 0 && substr($buffer, $pos - 1, 1) eq "\n");
        }

        my $has_selection = length($selection_start) && length($selection_end) && $selection_start != $selection_end;
        my ($start, $end);

        if ($action eq "extend" && $has_selection) {
            ($start, $end) = sort { $a <=> $b } ($selection_start, $selection_end);
            if (is_line_start($start) && is_line_end($end)) {
                if ($end < $length) {
                    my (undef, $next_end) = bounds_at($end);
                    $end = $next_end;
                }
            } else {
                ($start, $end) = bounds_at($cursor);
            }
        } elsif ($action eq "expand" && $has_selection) {
            my ($left, $right) = sort { $a <=> $b } ($selection_start, $selection_end);
            my $last = $right > $left ? $right - 1 : $cursor;
            ($start) = bounds_at($left);
            (undef, $end) = bounds_at($last);
        } elsif ($action eq "shrink" && $has_selection) {
            my ($left, $right) = sort { $a <=> $b } ($selection_start, $selection_end);
            $start = $left;
            if (!is_line_start($start)) {
                my $next = index($buffer, "\n", $start);
                $start = $next < 0 ? $right : $next + 1;
            }

            $end = $right;
            if (!is_line_end($end)) {
                my $previous = rindex($buffer, "\n", $end - 1);
                $end = $previous < 0 ? $left : $previous + 1;
            }

            if ($start >= $end) {
                ($start, $end) = ($left, $right);
            }
        } else {
            ($start, $end) = bounds_at($cursor);
        }

        print $start, " ", $end, "\n";
    ' $action (commandline -C) (commandline -B) (commandline -E) |
    read -l start end
    or return

    __fish_helix_select_range $start $end
end

function __fish_helix_join_lines
    set -l selection_start (commandline -B)
    set -l selection_end (commandline -E)
    test -n "$selection_start"
    or return
    test -n "$selection_end"
    or return

    set -l result (commandline --current-buffer |
    perl -CS -Mutf8 -e '
        use open qw(:std :utf8);
        my ($selection_start, $selection_end) = @ARGV;
        my $buffer = do { local $/; <STDIN> };
        chomp $buffer;
        my ($start, $end) = sort { $a <=> $b } ($selection_start, $selection_end);
        my $part = substr($buffer, $start, $end - $start);
        exit 1 unless $part =~ /\n/;
        $part =~ s/[ \t]*\n[ \t]*/ /g;
        my $updated = substr($buffer, 0, $start) . $part . substr($buffer, $end);
        print $updated, "\0", $start + length($part), "\0";
    ' $selection_start $selection_end | string split0)
    or return

    commandline $result[1]
    __fish_helix_select_range $selection_start $result[2]
end

function __fish_helix_find_next_cr -a mode count skip
    set -l cursor (commandline -C)
    commandline | # Include endling newline intentionally
    # Skip until cursor:
    sed -z 's/^.\{'(math $cursor + $skip)'\}\(.*\)$/\\1/' |
    # Count characters up to the target newline:
    sed -z 's/^\(\([^\\n]*\\n\)\{0,'$count'\}\).*/\\1/' |
    read -zl chars

    if test $mode = default -a -n "$chars"
        commandline -f begin-selection
    end
    for i in (seq 1 (string length -- "$chars"))
        commandline -f forward-char
    end
end

function __fish_helix_find_prev_cr -a mode count skip
    set -l cursor (commandline -C)
    commandline --cut-at-cursor |
    sed -z 's/.\{'$skip'\}\n$//' |
    read -zl buffer

    echo -n $buffer |
    # Drop characters up to the target newline:
    sed -z 's/\(\(\\n[^\\n]*\)\{0,'$count'\}\)$//' |
    read -zl chars
    set -l n_chars (math (string length -- "$buffer") - (string length -- "$chars"))

    if test $mode = default -a $n_chars != 0
        commandline -f begin-selection
    end
    for i in (seq 1 $n_chars)
        commandline -f backward-char
    end
end

function __fish_helix_goto_line_end
    # check if we are on an empty line first
    commandline | sed -n (commandline -L)'!b;/^$/q;q5' && return
    commandline -f end-of-line backward-char
end

function __fish_helix_goto_first_nonwhitespace
    # check if we are on whitespace line first
    commandline | sed -n (commandline -L)'!b;/^\\s*$/q;q5' && return
    commandline -f beginning-of-line forward-bigword backward-bigword
end

function __fish_helix_goto_line -a number
    set -l lines (math min\($number, (commandline | wc -l)\))
    commandline -f beginning-of-buffer
    for i in (seq 2 $lines)
        commandline -f down-line
    end
    __fish_helix_extend_by_mode
end

function __fish_helix_char_up -a mode count
    if commandline --paging-mode && not commandline --search-mode
        for i in (seq 1 $count)
            commandline -f up-line
        end
        return
    end
    set -l line (commandline -L)
    if commandline --search-mode || test $line = 1
        for i in (seq 1 (math min \($count, (count $history)\)))
            commandline -f history-search-backward
        end
        return
    end
    set -l count (math min\($count, $line-1\))
    for i in (seq 1 $count)
        commandline -f up-line
    end
    __fish_helix_extend_by_mode
end

function __fish_helix_char_down -a mode count
    if commandline --paging-mode && not commandline --search-mode
        for i in (seq 1 $count)
            commandline -f down-line
        end
        return
    end
    set -l line (commandline -L)
    set -l total (count (commandline))
    if commandline --search-mode || test $line = $total
        for i in (seq 1 (math min \($count, (count $history)\)))
            commandline -f history-search-forward
        end
        return
    end
    set -l count (math min\($count, $total - $line\))
    for i in (seq 1 $count)
        commandline -f down-line
    end
    __fish_helix_extend_by_mode
end

function __fish_helix_next_word -a mode count regex
    set -f cursor (commandline -C)
    commandline |
    perl -e '
        use open qw(:std :utf8);
        do { local $/; substr <>, '$cursor' } =~ m/(?:'$regex'){0,'$count'}/ux;
        print $-[1], " ", $+[1];' |
    read -f left right
    if test "$left" = "$right"
        commandline --current-buffer |
        perl -0 -e 'chomp; exit substr($_, -1) eq "\n" ? 0 : 1'
        or return

        commandline -C (math $cursor + $left)
        if test $mode = default
            commandline -f begin-selection
        end
        return
    end
    if test $mode = default
        commandline -C (math $cursor + $left)
        commandline -f begin-selection
        for i in (seq $left (math $right - 2))
            commandline -f forward-char
        end
    else
        commandline -C (math $cursor + $right - 1)
    end
end

function __fish_helix_prev_word -a mode count regex
    set -f left (math (commandline -C) + 1)
    set -f updated 0
    for i in (seq 1 $count)
        commandline |
        perl -e '
            use open qw(:std :utf8);
            do { local $/; substr <>, 0, '$left' } =~ /(?:'$regex')$/ux;
            print $-[1], " ", $+[1];' |
        read -l l r
        test "$l" = "$r" -o "$l" = 0 -a "$r" = 1 && break
        set -f left $l
        set -f right $r
        set -f updated 1
    end
    test $updated -eq 0; and return
    if test $mode = default
        commandline -C (math $right - 1)
        commandline -f begin-selection
        for i in (seq $left (math $right - 2))
            commandline -f backward-char
        end
    else
        commandline -C (math $left)
    end
end

function __fish_helix_delete_selection
    set start (commandline -B)
    set end (commandline -E)
    commandline |
    sed -zE 's/^(.{'$start'})(.{0,'(math $end - $start)'})(.*)\\n$/\\1\\3/' |
    read -l result

    commandline "$result"
    commandline -C $start
    commandline -f begin-selection
end

function __fish_helix_yank
    set -l end (commandline -E)
    set -l cursor (commandline -C)
    commandline -f kill-selection yank backward-char

    for i in (seq $cursor (math $end - 2))
        commandline -f backward-char
    end
end

function __fish_helix_paste_before -a cmd_paste
    set -l cmd_paste $(string split " " $cmd_paste)
    set -l cursor (commandline -C)
    set -l start (commandline -B)
    set -l end (commandline -E)
    if test -z "$start" -o -z "$end"
        commandline -C $cursor
        $cmd_paste
        commandline -f end-selection
        return
    end
    commandline -C $start
    $cmd_paste
    commandline -f begin-selection
    for i in (seq $start (math $end - 2))
        commandline -f forward-char
    end
    if test $cursor = $start
        commandline -f swap-selection-start-stop
    end
end

function __fish_helix_paste_after -a cmd_paste
    set -l cmd_paste $(string split " " $cmd_paste)
    set -l cursor (commandline -C)
    set -l start (commandline -B)
    set -l end (commandline -E)
    if test -z "$start" -o -z "$end"
        commandline -C $cursor
        $cmd_paste
        commandline -f end-selection
        return
    end
    commandline -C $end
    $cmd_paste

    if test "$argv[2]" = "--clip"
        commandline -C (math $end - 1)
    else
        for i in (seq 0 (string length "$fish_killring[1]"))
            commandline -f backward-char
        end
    end
    commandline -f begin-selection
    for i in (seq $start (math $end - 2))
        commandline -f backward-char
    end
    if test $cursor != $start
        commandline -f swap-selection-start-stop
    end
end

function __fish_helix_replace_selection -a replacement cmd_paste
    set -l cmd_paste $(string split " " $cmd_paste)
    set cursor (commandline -C)
    set start (commandline -B)
    set end (commandline -E)
    commandline |
    sed -zE 's/^(.{'$start'})(.{0,'(math $end - $start)'})(.*)\\n$/\\1'"$(string escape --style=regex "$replacement")"'\\3/' |
    read -l result

    commandline "$result"
    commandline -C $start
    $cmd_paste

    if test "$argv[3]" = --clip
        commandline -f backward-char begin-selection
        for i in (seq (math $start + 2) (commandline -C))
            commandline -f backward-char
        end
        if test $cursor != $start
            commandline -f swap-selection-start-stop
        end
    else
        commandline -f begin-selection
        for i in (seq 2 (string length "$replacement"))
            commandline -f forward-char
        end
        if test $cursor = $start
            commandline -f swap-selection-start-stop
        end
    end
end
