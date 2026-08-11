set fish_bind_mode fish_helix_find_char
set __fish_helix_find_char_mode default
if not fish_default_mode_prompt | string match -q '*[N]*'
    echo "Mode prompt did not show [N] while waiting for a character search key" >> "$temp_dir/out"
    touch "$temp_dir/failure"
end

set __fish_helix_find_char_mode visual
if not fish_default_mode_prompt | string match -q '*[V]*'
    echo "Mode prompt did not show [V] while waiting for a character search key" >> "$temp_dir/out"
    touch "$temp_dir/failure"
end
