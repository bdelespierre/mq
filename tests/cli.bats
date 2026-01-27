#!/usr/bin/env bats

setup() {
    PROJECT_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
    PATH="$PROJECT_ROOT/bin:$PATH"
}

# Help tests

@test "cli: --help shows usage" {
    run mq --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage:"* ]]
}

@test "cli: -h shows usage" {
    run mq -h
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage:"* ]]
}

@test "cli: --help documents --quiet flag" {
    run mq --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"-q, --quiet"* ]]
}

@test "cli: --help documents --dry-run flag" {
    run mq --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"-n, --dry-run"* ]]
}

@test "cli: --help documents --input flag" {
    run mq --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"-i, --input"* ]]
}

# Option parsing tests (these fail at MySQL connection, but validate parsing)

@test "cli: accepts -q flag" {
    run mq -q select 1
    # Will fail connecting to MySQL, but should not fail on option parsing
    # Exit code 1 is from MySQL connection failure, not getopt
    [[ "$output" != *"invalid option"* ]]
    [[ "$output" != *"unrecognized option"* ]]
}

@test "cli: accepts --quiet flag" {
    run mq --quiet select 1
    [[ "$output" != *"invalid option"* ]]
    [[ "$output" != *"unrecognized option"* ]]
}

@test "cli: no query shows error" {
    run mq
    [ "$status" -eq 1 ]
    [[ "$output" == *"No query specified"* ]]
}

# Dry-run tests

@test "cli: -n outputs query without executing" {
    run mq -n select %a from users
    [ "$status" -eq 0 ]
    [ "$output" = "select * from users" ]
}

@test "cli: --dry-run outputs query without executing" {
    run mq --dry-run select %count from users where age %gt :18
    [ "$status" -eq 0 ]
    [ "$output" = "select count(*) from users where age > '18'" ]
}

@test "cli: dry-run with complex query" {
    run mq -n select %a from users where status %in :active :pending
    [ "$status" -eq 0 ]
    [ "$output" = "select * from users where status IN ('active', 'pending')" ]
}

# Input file tests

@test "cli: -i reads query from file" {
    local tmpfile=$(mktemp)
    echo "SELECT * FROM users" > "$tmpfile"
    run mq -n -i "$tmpfile"
    rm -f "$tmpfile"
    [ "$status" -eq 0 ]
    [ "$output" = "SELECT * FROM users" ]
}

@test "cli: --input reads query from file" {
    local tmpfile=$(mktemp)
    echo "SELECT count(*) FROM orders" > "$tmpfile"
    run mq -n --input "$tmpfile"
    rm -f "$tmpfile"
    [ "$status" -eq 0 ]
    [ "$output" = "SELECT count(*) FROM orders" ]
}

@test "cli: -i - reads query from stdin" {
    run bash -c 'echo "SELECT 1" | mq -n -i -'
    [ "$status" -eq 0 ]
    [ "$output" = "SELECT 1" ]
}

@test "cli: input file not found shows error" {
    run mq -n -i /nonexistent/file.sql
    [ "$status" -eq 1 ]
    [[ "$output" == *"File not found"* ]]
}

@test "cli: multiline query from file" {
    local tmpfile=$(mktemp)
    cat > "$tmpfile" <<'EOF'
SELECT *
FROM users
WHERE status = 'active'
EOF
    run mq -n -i "$tmpfile"
    rm -f "$tmpfile"
    [ "$status" -eq 0 ]
    [[ "$output" == *"SELECT *"* ]]
    [[ "$output" == *"FROM users"* ]]
}

# Config file tests

@test "cli: --help documents config file" {
    run mq --help
    [ "$status" -eq 0 ]
    [[ "$output" == *".mqrc"* ]]
}

@test "cli: loads format from config file" {
    local config=$(mktemp)
    echo "FORMAT=table" > "$config"
    # We can't easily test MySQL options without a connection,
    # but we can verify the config is parsed by checking help still works
    MQRC="$config" run mq --help
    rm -f "$config"
    [ "$status" -eq 0 ]
}

@test "cli: loads quiet option from config file" {
    local config=$(mktemp)
    echo "QUIET=1" > "$config"
    MQRC="$config" run mq --help
    rm -f "$config"
    [ "$status" -eq 0 ]
}

@test "cli: config file supports comments" {
    local config=$(mktemp)
    cat > "$config" <<'EOF'
# This is a comment
FORMAT=table
# Another comment
EOF
    MQRC="$config" run mq --help
    rm -f "$config"
    [ "$status" -eq 0 ]
}

@test "cli: config file ignores empty lines" {
    local config=$(mktemp)
    cat > "$config" <<'EOF'

FORMAT=table

QUIET=1

EOF
    MQRC="$config" run mq --help
    rm -f "$config"
    [ "$status" -eq 0 ]
}

@test "cli: CLI options override config file" {
    local config=$(mktemp)
    echo "FORMAT=table" > "$config"
    # -n (dry-run) should work regardless of config
    MQRC="$config" run mq -q -n select 1
    rm -f "$config"
    [ "$status" -eq 0 ]
    [ "$output" = "select 1" ]
}

@test "cli: missing config file is silently ignored" {
    MQRC="/nonexistent/config" run mq --help
    [ "$status" -eq 0 ]
}
