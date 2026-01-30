#!/usr/env bash
#
# demo.sh - mq demo script for Terminalizer recording
#
# Usage:
#   terminalizer record demo
#   # then run: source demo.sh
#   terminalizer render demo
#
# Requires: mq_demo database (see README)

set -euo pipefail

DB="-o database=mq_demo"

pause() { sleep "${1:-1.5}"; }
header() { echo -e "\033[1;36m# $*\033[0m"; pause 0.8; }

# Simulate typing a command character by character, then execute it
type_cmd() {
    local cmd="$*"
    local char delay
    printf '\033[1;32m$\033[0m '
    for (( i=0; i<${#cmd}; i++ )); do
        char="${cmd:$i:1}"
        printf '%s' "$char"
        delay="0.0$(( RANDOM % 8 + 2 ))"
        sleep "$delay"
    done
    echo
    sleep 0.5
    eval "$cmd"
    echo
}

clear

header "Count active users"
type_cmd mq $DB -q select %count from users where status=:active
pause

header "String values with :shorthand"
type_cmd mq $DB -q select name, email from users where role=:admin
pause

header "Comparison operators: %gt %lte"
type_cmd mq $DB -q select name, age from users where age %gt :40
pause

header "IN clause"
type_cmd mq $DB -q select name, role from users where role %in :admin :editor
pause

header "BETWEEN operator"
type_cmd mq $DB -q select name, birthdate from users where birthdate %between :1990-01-01 :2000-01-01
pause

header "Aggregate functions"
type_cmd mq $DB -q select %min age, %max age, %avg score from users
pause

header "JSON extraction"
type_cmd mq $DB -q select name, %json settings.theme as theme, %json settings.lang as lang from users limit 5
pause 2

header "Vertical output with trailing +"
type_cmd mq $DB -q select %a from users where email=:alice@example.com +
pause 2

header "CSV output"
type_cmd mq $DB -q -f csv select name, email, status from users limit 5
pause 2

header "JSON output"
type_cmd mq $DB -q -f json select name, score from users limit 3
pause 2

header "Dry-run mode (show SQL without executing)"
type_cmd mq -n select %count from users where status=:active and age %gte :30
pause

header "Query bookmarks"
type_cmd mq $DB -n --save top-scorers select name, score from users where score %gte :90 order by score desc
pause

type_cmd mq --list
pause

type_cmd mq --show top-scorers
pause

type_cmd mq $DB -q --run top-scorers
pause

type_cmd mq --delete top-scorers
pause

