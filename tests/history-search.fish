if not bind --preset -M default / | string match -q '*history-pager*'
    echo "Normal-mode / is not bound to history-pager" >>"$temp_dir/out"
    touch "$temp_dir/failure"
end

_input Normal / Pause
_mode insert
