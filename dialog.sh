#!/usr/bin/env bash
# dialog.sh - common dialog/termux-dialog/bash widget wrapper

set -u

dialog(){

showhelp() {
    cat >&2 <<EOF
dialog.sh - common dialog, Termux, and Bash widget wrapper

Usage:
  ${BASH_SOURCE[0]} <widget> <prompt> [options] [--] [choices...]

Widgets:
  select       Select one item.
  multiselect  Select one or more items.
  yesno        Ask a yes/no question.
  msgbox       Display a message.
  line         Read a line of text.
  password     Read a password or other secret.
  date         Read a date in YYYY-MM-DD format.
  time         Read a time in HH:MM format.

Options:
  --title <title>       Set the dialog title.
  --default <value>     Set the default value or selected tag.
  --height <number>     Set the dialog height. Default: 0.
  --width <number>      Set the dialog width. Default: 0.
  --config <line>       Use this implementation configuration instead of
                        .dialog.conf.
  --                    Stop option processing; remaining arguments are
                        treated as choices.
  --help                Display this help message.

Choices:
  Choices are normally supplied after the prompt and options.

  A choice may be written as:
    tag=label

  For dialog-based widgets, tag is returned and label is displayed.
  For other implementations, the behavior depends on the implementation.

Configuration:
  A file named .dialog.conf may be placed in the same directory as this
  script. Each line has the following format:

    widget: implementation implementation ...

  Example:

    select: dialog:menu termux-dialog:radio termux-dialog:sheet bash:select
    multiselect: dialog:checklist termux-dialog:checkbox bash:multiselect
    yesno: dialog:yesno termux-dialog:confirm bash:normal bash:fast
    msgbox: dialog:msgbox bash:msgbox
    line: dialog:inputbox termux-dialog:text bash:normal
    password: dialog:passwordbox termux-dialog:text bash pinentry systemd ssh-askpass
    date: dialog:calendar termux-dialog:date bash:date
    time: dialog:timebox termux-dialog:time bash:time

Supported implementation names include:

  dialog:<widget>          Uses the dialog program.
  termux-dialog:<widget>   Uses Termux:API's termux-dialog command.
  bash:<mode>              Uses terminal input with Bash.
  pinentry[:program]       Uses a Pinentry-compatible program.
  systemd                  Uses systemd-ask-password.
  ssh-askpass[:program]    Uses an SSH askpass program for passwords.

The special implementations shuffle and randomize shuffle the rest of the
implementation list. They do NOT shuffle any listed before.

Return codes:
  0  Accepted or selected.
  1  Cancelled, declined, or no input.
  2  No usable implementation was found.
  3  Configuration, argument, or other non-widget error.

Output:
  Successful values are written to stdout.
  Prompts and interactive messages are written to stderr.

Examples:
  ${BASH_SOURCE[0]} select "Choose a color" red green blue
  ${BASH_SOURCE[0]} select "Choose a color" red=Red green=Green
  ${BASH_SOURCE[0]} yesno "Continue?"
  ${BASH_SOURCE[0]} line "Enter your name"
  ${BASH_SOURCE[0]} password "Password"
  ${BASH_SOURCE[0]} date "Date"
  ${BASH_SOURCE[0]} time "Time"

This help text is provided by the help widget.
EOF
    return 3
}

local self_dir
self_dir=$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd) || return 3
readonly CONF="${self_dir}/.dialog.conf"

local WIDGET=${1-}
case "$WIDGET" in
--help|help|'') showhelp;;
esac
shift || true

local PROMPT=${1-}
shift || true

local TITLE=
local DEFAULT=
local HEIGHT=0
local WIDTH=0
local CONFIG_LINE=

# Options are removed before widget arguments are processed.
local ARGS=()
while (($#)); do
    case "$1" in
        --help) showhelp;;
        --title)
            (($# >= 2)) || { echo "--title requires an argument" >&2; return 3; }
            TITLE=$2
            shift 2
            ;;
        --default)
            (($# >= 2)) || { echo "--default requires an argument" >&2; return 3; }
            DEFAULT=$2
            shift 2
            ;;
        --height)
            (($# >= 2)) || { echo "--height requires an argument" >&2; return 3; }
            HEIGHT=$2
            shift 2
            ;;
        --width)
            (($# >= 2)) || { echo "--width requires an argument" >&2; return 3; }
            WIDTH=$2
            shift 2
            ;;
        --config)
            (($# >= 2)) || { echo "--config requires an argument" >&2; return 3; }
            CONFIG_LINE=$2
            shift 2
            ;;
        --)
            shift
            ARGS+=("$@")
            break
            ;;
        *)
            ARGS+=("$1")
            shift
            ;;
    esac
done

# Read implementations from .dialog.conf.
#
get_implementations() {
    local line key value
    local wanted=$1

    if [[ -n "$CONFIG_LINE" ]]; then
        printf '%s\n' "$CONFIG_LINE"
        return
    fi

    if [[ -f "$CONF" ]]; then
        while IFS= read -r line || [[ -n "$line" ]]; do
            line=${line%%#*}
            [[ $line =~ ^[[:space:]]*$ ]] && continue
            key=${line%%:*}
            value=${line#*:}
            key=${key//[[:space:]]/}
            if [[ $key == "$wanted" ]]; then
                printf '%s\n' "$value"
                return
            fi
        done < "$CONF"
    fi

    # Useful defaults when no configuration file exists.
    case "$wanted" in
        select)      printf '%s\n' 'dialog:menu termux-dialog:radio termux-dialog:sheet termux-dialog:spinner bash:select' ;;
        multiselect) printf '%s\n' 'dialog:checklist termux-dialog:checkbox bash:multiselect' ;;
        yesno)       printf '%s\n' 'dialog:yesno termux-dialog:confirm bash:normal bash:fast' ;;
        msgbox)      printf '%s\n' 'dialog:msgbox bash:msgbox' ;;
        password)    printf '%s\n' 'dialog:passwordbox termux-dialog:text bash pinentry systemd' ;;
        date)        printf '%s\n' 'dialog:calendar termux-dialog:date bash:date' ;;
        time)        printf '%s\n' 'dialog:timebox termux-dialog:time bash:time' ;;
        *)           return 3 ;;
    esac
}

run_dialog() {
    local impl=$1
    local kind=${impl#dialog:}
    local out rc
    local -a cmd=(dialog --stdout)

    [[ -n $TITLE ]] && cmd+=(--title "$TITLE")

    case "$WIDGET:$kind" in
        select:menu)
            cmd+=(--menu "$PROMPT" "$HEIGHT" "$WIDTH" 0)
            local x tag label
            for x in "${ARGS[@]}"; do
                if [[ $x == *=* ]]; then
                    tag=${x%%=*}; label=${x#*=}
                else
                    tag=$x; label=$x
                fi
                cmd+=("$tag" "$label")
            done
            ;;
        multiselect:checklist|select:radiolist)
            local box=checklist
            [[ $kind == radiolist ]] && box=radiolist
            cmd+=(--"$box" "$PROMPT" "$HEIGHT" "$WIDTH" 0)
            local x tag label status
            for x in "${ARGS[@]}"; do
                if [[ $x == *=* ]]; then
                    tag=${x%%=*}; label=${x#*=}
                else
                    tag=$x; label=$x
                fi
                status=off
                [[ ",$DEFAULT," == *",$tag,"* ]] && status=on
                cmd+=("$tag" "$label" "$status")
            done
            ;;
        msgbox:msgbox|yesno:yesno) cmd+=("--$kind" "$PROMPT" "$HEIGHT" "$WIDTH") ;;
        line:inputbox|password:passwordbox) cmd+=("--$kind" "$PROMPT" "$HEIGHT" "$WIDTH" "$DEFAULT") ;;
        date:calendar) cmd+=(--calendar "$PROMPT" "$HEIGHT" "$WIDTH") ;;
        time:timebox) cmd+=(--timebox "$PROMPT" "$HEIGHT" "$WIDTH" 0 0 0) ;;
        *) return 2 ;;
    esac

    out=$("${cmd[@]}" 2>/dev/tty)
    rc=$?

    case $rc in
        0) printf '%s\n' "$out"; return 0 ;;
        1|255) return 1 ;;
        *) return 3 ;;
    esac
}

run_termux() {
    local impl=$1
    local kind=${impl#termux-dialog:}
    local out code text
    local -a cmd=(termux-dialog)

    command -v termux-dialog >/dev/null 2>&1 || return 2

    case "$WIDGET:$kind" in
        yesno:confirm)
            cmd+=(confirm -i "$PROMPT")
            ;;
        select:radio|select:sheet|select:spinner)
            local vals=()
            local x
            for x in "${ARGS[@]}"; do
                [[ $x == *=* ]] && x=${x#*=}
                vals+=("$x")
            done
            local IFS=,
            cmd+=("$kind" -v "${vals[*]}")
            [[ -n $TITLE ]] && cmd+=(-t "$TITLE")
            ;;
        multiselect:checkbox)
            local vals=()
            local x
            for x in "${ARGS[@]}"; do
                [[ $x == *=* ]] && x=${x#*=}
                vals+=("$x")
            done
            local IFS=,
            cmd+=(checkbox -v "${vals[*]}")
            [[ -n $TITLE ]] && cmd+=(-t "$TITLE")
            ;;
	line:text)
	    cmd+=(text -i "$PROMPT")
            [[ -n $TITLE ]] && cmd+=(-t "$TITLE")
            ;;
        password:text)
            cmd+=(text -p -i "$PROMPT")
            [[ -n $TITLE ]] && cmd+=(-t "$TITLE")
            ;;
        date:date) cmd+=(date); [[ -n $TITLE ]] && cmd+=(-t "$TITLE") ;;
        time:time) cmd+=(time); [[ -n $TITLE ]] && cmd+=(-t "$TITLE") ;;
        *) return 2 ;;
    esac
    code=3
    text=''
    complete=no
    while read -r var val
    do
	    case "$var" in
	    code) code="$val";;
	    text) text=$(sed -n -E '
s/\\n/\
/g
s/\\t/	/g
s/\\"/"/g
s/\\\\/\\/g
' <<<"$val");;
            '}') complete=yes
	    esac

    done < <("${cmd[@]}"|sed -n -E '
/^[}]$/p;
s/^[[:space:]]*"code"[[:space:]]*:[[:space:]]*(-?[0-9]+)[^-0-9]*$/code \1/p;
s/^[[:space:]]*"text"[[:space:]]*:[[:space:]]*"(.*)"[^"]*$/text \1/p
')
    [ "$complete" = no ]&&return 3 # could redo in case of orientation change, but this is safer in case it's due to some other issue

    case "$WIDGET:$kind:$code" in
        yesno:confirm:0)
            [[ $text == yes ]] && return 0
            return 1
            ;;
        *:-1)
            printf '%s\n' "$text"
            return 0
            ;;
        *:-2) return 1 ;;
        *) return 3 ;;
    esac
}

bash_select() {
    local multi=$1
    local -a values=("${ARGS[@]}")
    local i tag label answer
    local IFS=,

    PS3="${PROMPT} "
    if ((multi)); then
        select answer in "${values[@]}" "Cancel"; do
            [[ $REPLY == $(( ${#values[@]} + 1 )) ]] && return 1
            ((REPLY >= 1 && REPLY <= ${#values[@]})) || continue
            printf '%s\n' "${values[REPLY-1]}"
            return 0
        done
    else
        select answer in "${values[@]}" "Cancel"; do
            [[ $REPLY == $(( ${#values[@]} + 1 )) ]] && return 1
            ((REPLY >= 1 && REPLY <= ${#values[@]})) || continue
            printf '%s\n' "${values[REPLY-1]}"
            return 0
        done
    fi
}

run_bash() {
    local impl=$1
    local kind=${impl#bash:}
    local answer

    case "$WIDGET:$kind" in
        yesno:fast)
            printf '%s [y/N] ' "$PROMPT" >&2
            IFS= read -r -n 1 answer
            printf '\n' >&2
            [[ $answer =~ ^[Yy]$ ]] && return 0
            return 1
            ;;
        yesno:*)
            printf '%s [y/N] ' "$PROMPT" >&2
            IFS= read -r answer || return 1
            [[ $answer =~ ^[Yy]([Ee][Ss])?$ ]] && return 0
            return 1
            ;;
        msgbox:*)
            printf '%s\n' "$PROMPT" >&2
            IFS= read -r -p 'Press Enter to continue... ' answer || true
            return 0
            ;;
        line:*)
            printf '%s ' "$PROMPT" >&2
            IFS= read -r answer || return 1
            printf '\n' >&2
            printf '%s\n' "$answer"
            return 0
            ;;
        password:*)
            printf '%s ' "$PROMPT" >&2
            IFS= read -r -s answer || return 1
            printf '\n' >&2
            printf '%s\n' "$answer"
            return 0
            ;;
        select:*) bash_select 0 ;;
        multiselect:*) bash_select 1 ;;
        date:*)
            printf '%s [YYYY-MM-DD] ' "$PROMPT" >&2
            IFS= read -r answer || return 1
            [[ $answer =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || return 3
            printf '%s\n' "$answer"
            return 0
            ;;
        time:*)
            printf '%s [HH:MM] ' "$PROMPT" >&2
            IFS= read -r answer || return 1
            [[ $answer =~ ^([01][0-9]|2[0-3]):[0-5][0-9]$ ]] || return 3
            printf '%s\n' "$answer"
            return 0
            ;;
        *) return 2 ;;
    esac
}

assuan_unescape() {
    local input=$1
    local output=
    local i=0
    local c n hex

    while ((i < ${#input})); do
        c=${input:i:1}

        if [[ $c != \\ ]]; then
            output+=$c
            ((i++))
            continue
        fi

        # A backslash at the end is preserved.
        if ((i + 1 >= ${#input})); then
            output+=\\
            ((i++))
            continue
        fi

        n=${input:i+1:1}

        case "$n" in
            # Assuan hexadecimal escape: \xHH
            x|X)
                if ((i + 3 < ${#input})) &&
                   [[ ${input:i+2:2} =~ ^[[:xdigit:]]{2}$ ]]; then
                    hex=${input:i+2:2}
		    #shellcheck disable=SC2059
                    printf -v c "\\x$hex"
                    output+=$c
                    ((i += 4))
                else
                    output+="\\$n"
                    ((i += 2))
                fi
                ;;
            # Common textual escapes.
            n)
                output+=$'\n'
                ((i += 2))
                ;;
            r)
                output+=$'\r'
                ((i += 2))
                ;;
            t)
                output+=$'\t'
                ((i += 2))
                ;;
            \\)
                output+=\\
                ((i += 2))
                ;;
            *)
                # Preserve unknown escapes rather than silently changing
                # the password.
                output+="\\$n"
                ((i += 2))
                ;;
        esac
    done

    printf '%s' "$output"
}

run_pinentry() {
    local impl=$1
    local program=${impl#pinentry:}
    local line decoded
    local status=1

    [[ $program == "$impl" ]] && program=pinentry

    command -v "$program" >/dev/null 2>&1 || return 2

    while IFS= read -r line; do
        case "$line" in
            D\ *)
                decoded=$(assuan_unescape "${line#D }") || return 3
                ;;
            OK\ *)
                printf '%s\n' "${decoded-}"
                status=0
                break
                ;;
            ERR\ *)
                status=1
                break
                ;;
        esac
    done < <(
        {
            printf 'SETDESC %s\n' "$PROMPT"
            printf 'SETPROMPT Password:\n'
            printf 'GETPIN\n'
            printf 'BYE\n'
        } | "$program" 2>/dev/null
    )

    return "$status"
}

run_systemd() {
    command -v systemd-ask-password >/dev/null 2>&1 || return 2
    systemd-ask-password --no-tty "$PROMPT"
}

run_ssh_askpass() {
    local impl=$1
    local program=${impl#ssh-askpass:}
    local result

    [[ $program == "$impl" ]] && program=ssh-askpass

    command -v "$program" >/dev/null 2>&1 || return 2

    # ssh-askpass programs receive the prompt as argv[1] and return the
    # entered secret on stdout.
    result=$("$program" "$PROMPT" 2>/dev/null) || return 1
    printf '%s\n' "$result"
    return 0
}

run_one() {
    local impl=$1
    case "$impl" in
        dialog|dialog:*) command -v dialog >/dev/null 2>&1 || return 2; run_dialog "$impl" ;;
        termux-dialog|termux-dialog:*) run_termux "${impl#termux-dialog}" ;;
        bash|bash:*) run_bash "$impl" ;;
        pinentry|pinentry:*) run_pinentry "$impl" ;;
        systemd) run_systemd ;;
        ssh-askpass|ssh-askpass:*)
            [[ $WIDGET == password ]] || return 2
            run_ssh_askpass "$impl"
            ;;
        *) return 2 ;;
    esac
}

mapfile -t IMPLS < <(get_implementations "$WIDGET") || return 3
((${#IMPLS[@]})) || return 3

# Configuration lines may be whitespace-separated.
read -r -a IMPLS <<<"${IMPLS[0]}"

for ((I=0;I<${#IMPLS[@]};I++))
do
    case "${IMPLS[I]}" in
    shuffle|shuffle:*|randomize|randomize:*)
        for ((i=${#IMPLS[@]}-1; i>I; i--)); do
            j=$((RANDOM % (i + 1)))
            t=${IMPLS[i]}
            IMPLS[i]=${IMPLS[j]}
            IMPLS[j]=$t
        done
        continue;;
    *) run_one "${IMPLS[I]}"
    esac
    rc=$?

    case $rc in
        0|1) return "$rc" ;;
        2) continue ;;
        *) return 3 ;;
    esac
done

return 2

}

[ "${BASH_SOURCE[0]}" != "$0" ]||dialog "$@"

