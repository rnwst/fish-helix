function fish_default_mode_prompt --description "Display vi/helix prompt mode"
    # Do nothing if not in vi mode
    if test "$fish_key_bindings" = fish_vi_key_bindings
        or test "$fish_key_bindings" = fish_helix_key_bindings
        or test "$fish_key_bindings" = fish_hybrid_key_bindings
        set -l prompt_bind_mode $fish_bind_mode
        if test "$prompt_bind_mode" = fish_helix_find_char
            set prompt_bind_mode $__fish_helix_find_char_mode
            test -n "$prompt_bind_mode"
            or set prompt_bind_mode default
        end

        switch $prompt_bind_mode
            case default
                set_color --bold red
                echo '[N]'
            case insert
                set_color --bold green
                echo '[I]'
            case replace_one
                set_color --bold green
                echo '[R]'
            case replace
                set_color --bold cyan
                echo '[R]'
            case visual
                set_color --bold magenta
                echo '[V]'
        end
        set_color --reset
        echo -n ' '
    end
end
