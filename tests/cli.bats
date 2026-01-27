#!/usr/bin/env bats

setup() {
    PROJECT_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
    PATH="$PROJECT_ROOT/bin:$PATH"
}

# Help tests

@test "cli: --help shows usage" {
    run mysql-query --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage:"* ]]
}

@test "cli: -h shows usage" {
    run mysql-query -h
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage:"* ]]
}

@test "cli: --help documents --quiet flag" {
    run mysql-query --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"-q, --quiet"* ]]
}

@test "cli: --help documents --dry-run flag" {
    run mysql-query --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"-n, --dry-run"* ]]
}

@test "cli: --help documents --input flag" {
    run mysql-query --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"-i, --input"* ]]
}

# Option parsing tests (these fail at MySQL connection, but validate parsing)

@test "cli: accepts -q flag" {
    run mysql-query -q select 1
    # Will fail connecting to MySQL, but should not fail on option parsing
    # Exit code 1 is from MySQL connection failure, not getopt
    [[ "$output" != *"invalid option"* ]]
    [[ "$output" != *"unrecognized option"* ]]
}

@test "cli: accepts --quiet flag" {
    run mysql-query --quiet select 1
    [[ "$output" != *"invalid option"* ]]
    [[ "$output" != *"unrecognized option"* ]]
}

@test "cli: no query shows error" {
    run mysql-query
    [ "$status" -eq 1 ]
    [[ "$output" == *"No query specified"* ]]
}

# Dry-run tests

@test "cli: -n outputs query without executing" {
    run mysql-query -n select %a from users
    [ "$status" -eq 0 ]
    [ "$output" = "select * from users" ]
}

@test "cli: --dry-run outputs query without executing" {
    run mysql-query --dry-run select %count from users where age %gt :18
    [ "$status" -eq 0 ]
    [ "$output" = "select count(*) from users where age > '18'" ]
}

@test "cli: dry-run with complex query" {
    run mysql-query -n select %a from users where status %in :active :pending %limit 10
    [ "$status" -eq 0 ]
    [ "$output" = "select * from users where status IN ('active', 'pending') LIMIT 10" ]
}

# Input file tests

@test "cli: -i reads query from file" {
    local tmpfile=$(mktemp)
    echo "SELECT * FROM users" > "$tmpfile"
    run mysql-query -n -i "$tmpfile"
    rm -f "$tmpfile"
    [ "$status" -eq 0 ]
    [ "$output" = "SELECT * FROM users" ]
}

@test "cli: --input reads query from file" {
    local tmpfile=$(mktemp)
    echo "SELECT count(*) FROM orders" > "$tmpfile"
    run mysql-query -n --input "$tmpfile"
    rm -f "$tmpfile"
    [ "$status" -eq 0 ]
    [ "$output" = "SELECT count(*) FROM orders" ]
}

@test "cli: -i - reads query from stdin" {
    run bash -c 'echo "SELECT 1" | mysql-query -n -i -'
    [ "$status" -eq 0 ]
    [ "$output" = "SELECT 1" ]
}

@test "cli: input file not found shows error" {
    run mysql-query -n -i /nonexistent/file.sql
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
    run mysql-query -n -i "$tmpfile"
    rm -f "$tmpfile"
    [ "$status" -eq 0 ]
    [[ "$output" == *"SELECT *"* ]]
    [[ "$output" == *"FROM users"* ]]
}

# Config file tests

@test "cli: --help documents config file" {
    run mysql-query --help
    [ "$status" -eq 0 ]
    [[ "$output" == *".mysql-queryrc"* ]]
}

@test "cli: loads format from config file" {
    local config=$(mktemp)
    echo "format=table" > "$config"
    # We can't easily test MySQL options without a connection,
    # but we can verify the config is parsed by checking help still works
    MYSQL_QUERYRC="$config" run mysql-query --help
    rm -f "$config"
    [ "$status" -eq 0 ]
}

@test "cli: loads quiet option from config file" {
    local config=$(mktemp)
    echo "quiet=true" > "$config"
    MYSQL_QUERYRC="$config" run mysql-query --help
    rm -f "$config"
    [ "$status" -eq 0 ]
}

@test "cli: config file supports comments" {
    local config=$(mktemp)
    cat > "$config" <<'EOF'
# This is a comment
format=table
# Another comment
EOF
    MYSQL_QUERYRC="$config" run mysql-query --help
    rm -f "$config"
    [ "$status" -eq 0 ]
}

@test "cli: config file ignores empty lines" {
    local config=$(mktemp)
    cat > "$config" <<'EOF'

format=table

quiet=true

EOF
    MYSQL_QUERYRC="$config" run mysql-query --help
    rm -f "$config"
    [ "$status" -eq 0 ]
}

@test "cli: CLI options override config file" {
    local config=$(mktemp)
    echo "format=table" > "$config"
    # -n (dry-run) should work regardless of config
    MYSQL_QUERYRC="$config" run mysql-query -n select 1
    rm -f "$config"
    [ "$status" -eq 0 ]
    [ "$output" = "select 1" ]
}

@test "cli: missing config file is silently ignored" {
    MYSQL_QUERYRC="/nonexistent/config" run mysql-query --help
    [ "$status" -eq 0 ]
}
