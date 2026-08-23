#!/data/data/com.termux/files/usr/bin/bash
# Dialog wrapper to abstract between termux-dialog and dialog
# Usage: source this file, then call show_menu with your options
# Copilot-assisted implementation

# Detect which dialog tool is available
# Priority: TERMUX_DIALOG env var > termux-dialog > dialog
detect_dialog_tool() {
    if [[ -n "$TERMUX_DIALOG" ]]; then
        if [[ "$TERMUX_DIALOG" == "termux-dialog" ]] || [[ "$TERMUX_DIALOG" == "1" ]]; then
            if command -v termux-dialog &> /dev/null; then
                echo "termux-dialog"
                return 0
            fi
        elif [[ "$TERMUX_DIALOG" == "dialog" ]] || [[ "$TERMUX_DIALOG" == "2" ]]; then
            if command -v dialog &> /dev/null; then
                echo "dialog"
                return 0
            fi
        fi
    fi
    
    # Auto-detect: try termux-dialog first, then dialog
    if command -v termux-dialog &> /dev/null; then
        echo "termux-dialog"
        return 0
    elif command -v dialog &> /dev/null; then
        echo "dialog"
        return 0
    else
        return 1
    fi
}

# Show a menu and return the selected option
# Usage: show_menu "Title" "Description" tmpfile option1 label1 option2 label2 ...
# The selected option is written to tmpfile
show_menu() {
    local title="$1"
    local description="$2"
    local tmpfile="$3"
    shift 3
    
    local dialog_tool
    dialog_tool=$(detect_dialog_tool) || {
        echo "Error: Neither termux-dialog nor dialog found" >&2
        return 1
    }
    
    # Build arrays of options and labels from remaining arguments
    local -a options labels
    while [[ $# -gt 1 ]]; do
        options+=("$1")
        labels+=("$2")
        shift 2
    done
    
    if [[ "$dialog_tool" == "termux-dialog" ]]; then
        show_menu_termux_dialog "$title" "$tmpfile" "${options[@]}" "${labels[@]}"
    else
        show_menu_dialog "$title" "$description" "$tmpfile" "${options[@]}" "${labels[@]}"
    fi
}

# Use termux-dialog radio widget
show_menu_termux_dialog() {
    local title="$1"
    local tmpfile="$2"
    shift 2
    
    local -a options labels
    local i=0
    # Process all arguments: first half are options, second half are labels
    local count=$#
    local mid=$((count / 2))
    
    for ((i=0; i<mid; i++)); do
        options+=("${!((i+1))}")
        labels+=("${!((i+mid+1))}")
    done
    
    # Build comma-separated values for termux-dialog
    local values
    values=$(printf '%s,' "${labels[@]}" | sed 's/,$//')
    
    local result
    result=$(termux-dialog radio -v "$values" -t "$title" 2>&1)
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        # termux-dialog returns the label, we need to find the corresponding option
        local selected_label="$result"
        local j=0
        while [[ $j -lt ${#labels[@]} ]]; do
            if [[ "${labels[$j]}" == "$selected_label" ]]; then
                echo "${options[$j]}" > "$tmpfile"
                return 0
            fi
            ((j++))
        done
    fi
    
    return $exit_code
}

# Use standard dialog menu
show_menu_dialog() {
    local title="$1"
    local description="$2"
    local tmpfile="$3"
    shift 3
    
    # dialog expects menu items as: option1 label1 option2 label2 ...
    dialog --title "$title" --menu "$description" 0 0 0 "$@" 2>"$tmpfile"
}
