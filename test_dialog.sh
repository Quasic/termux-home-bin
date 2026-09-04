#!/usr/bin/env bash
set -u

SCRIPT=${1:-./dialog.sh}

if [[ ! -f $SCRIPT ]]; then
    echo "Usage: $0 PATH/TO/dialog.sh" >&2
    exit 2
fi

SCRIPT=$(CDPATH='' cd -- "$(dirname -- "$SCRIPT")" && pwd)/$(basename -- "$SCRIPT")

pass=0
fail=0

report_pass() {
    printf 'PASS: %s\n' "$1"
    ((pass += 1))
}

report_fail() {
    printf 'FAIL: %s\n' "$1" >&2
    ((fail += 1))
}

run_external() {
    local name=$1
    local simulation=$2
    local expected_rc=$3
    local expected_output=$4
    shift 4

    local rc actual

    actual=$(TERMUX_DIALOG_SIM=$simulation bash "$SCRIPT" --title "$simulation" "$@")
    rc=$?

    if [[ $rc == "$expected_rc" && $actual == "$expected_output" ]]; then
        report_pass "external: $name"
    else
        report_fail "external: $name"
        printf '  expected rc: %s\n' "$expected_rc" >&2
        printf '  actual rc:   %s\n' "$rc" >&2
        printf '  expected out: %q\n' "$expected_output" >&2
        printf '  actual out:   %q\n' "$actual" >&2
    fi
}

run_sourced() {
    local name=$1
    local simulation=$2
    local expected_rc=$3
    local expected_output=$4
    shift 4

    local rc actual

    actual=$(TERMUX_DIALOG_SIM=$simulation \
        bash -u -c '
            script=$1
            shift

            # shellcheck disable=SC1090
            source "$script"

            dialog "$@"
	    ' bash "$SCRIPT" --title "$simulation" "$@")

    rc=$?

    if [[ $rc == "$expected_rc" && $actual == "$expected_output" ]]; then
        report_pass "sourced:  $name"
    else
        report_fail "sourced:  $name"
        printf '  expected rc: %s\n' "$expected_rc" >&2
        printf '  actual rc:   %s\n' "$rc" >&2
        printf '  expected out: %q\n' "$expected_output" >&2
        printf '  actual out:   %q\n' "$actual" >&2
    fi
}

test_both() {
    local name=$1
    local simulation=$2
    local expected_rc=$3
    local expected_output=$4
    shift 4

    run_external "$name" "$simulation" "$expected_rc" "$expected_output" "$@"
    run_sourced  "$name" "$simulation" "$expected_rc" "$expected_output" "$@"
}

#
# Select
#
# The choice marker is deliberately inside the choice text. The simulator
# should always select the yes@ choice, regardless of its position.
#
test_both \
    "selects yes@ choice" \
    "" \
    0 \
    "yes@" \
    select "Pick one" \
    --config "termux-dialog:radio" \
    -- \
    no@ yes@ maybe@ no@

test_both \
    "select cancellation" \
    "cancel@" \
    1 \
    "" \
    select "Pick one" \
    --config "termux-dialog:radio" \
    -- \
    no@ maybe@ no@

#
# Multiselect
#
# Both yes@ choices should be selected. no@ choices should not be selected.
# Do not use maybe@ here because its behavior is intentionally nondeterministic.
#
test_both \
    "multiselects every yes@ choice" \
    "" \
    0 \
    $'yes@\nyes@' \
    multiselect "Pick several" \
    --config "termux-dialog:checkbox" \
    -- \
    no@ yes@ maybe-no@ yes@ no@

test_both \
    "multiselect cancellation" \
    "cancel@" \
    1 \
    "" \
    multiselect "Pick several" \
    --config "termux-dialog:checkbox" \
    -- \
    no@ yes@ no@

#
# Yes/no
#
# TERMUX_DIALOG_SIM controls the dialog, not a choice list.
#
test_both \
    "yesno yes" \
    "yes@" \
    0 \
    "" \
    yesno "Continue?" \
    --config "termux-dialog:confirm"

test_both \
    "yesno no" \
    "no@" \
    1 \
    "" \
    yesno "Continue?" \
    --config "termux-dialog:confirm"

test_both \
    "yesno cancellation" \
    "cancel@" \
    1 \
    "" \
    yesno "Continue?" \
    --config "termux-dialog:confirm"

#
# Message box
#
test_both \
    "message box" \
    "yes@" \
    0 \
    "" \
    msgbox "This is a test message" \
    --config "termux-dialog:text"

#
# Text input
#
test_both \
    "line input" \
    "pick@hello world" \
    0 \
    "hello world" \
    line "Enter text" \
    --config "termux-dialog:text"

test_both \
    "line cancellation" \
    "cancel@" \
    1 \
    "" \
    line "Enter text" \
    --config "termux-dialog:text"

#
# Password input
#
test_both \
    "password input" \
    "pick@secret-value" \
    0 \
    "secret-value" \
    password "Enter password" \
    --config "termux-dialog:text"

test_both \
    "password cancellation" \
    "cancel@" \
    1 \
    "" \
    password "Enter password" \
    --config "termux-dialog:text"

#
# Date and time
#
test_both \
    "date input" \
    "pick@2026-09-02" \
    0 \
    "2026-09-02" \
    date "Choose date" \
    --config "termux-dialog:date"

test_both \
    "time input" \
    "pick@14:30" \
    0 \
    "14:30" \
    time "Choose time" \
    --config "termux-dialog:time"

printf '\nResults: %d passed, %d failed\n' "$pass" "$fail"

((fail == 0))
