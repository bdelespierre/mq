#!/usr/bin/env bats

# Integration tests that validate SQL syntax against a real MySQL server.
# These tests are skipped if MySQL is not available or not configured.
#
# To run these tests, ensure MySQL is accessible. You can configure connection
# options via environment variables:
#   MYSQL_TEST_OPTIONS="--host=localhost --user=root"

setup() {
    PROJECT_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
    PATH="$PROJECT_ROOT/bin:$PATH"

    # Check if mysql client is available
    if ! command -v mysql &> /dev/null; then
        skip "mysql client not installed"
    fi

    # Check if we can connect to MySQL
    if ! mysql ${MYSQL_TEST_OPTIONS:-} -e "SELECT 1" &> /dev/null; then
        skip "cannot connect to MySQL server"
    fi
}

# Basic syntax validation tests

@test "integration: SELECT with count(*)" {
    sql=$(mq -n select %count)
    run mysql ${MYSQL_TEST_OPTIONS:-} -e "$sql"
    [ "$status" -eq 0 ]
}

@test "integration: SELECT with string literal" {
    sql=$(mq -n select :hello as greeting)
    run mysql ${MYSQL_TEST_OPTIONS:-} -e "$sql"
    [ "$status" -eq 0 ]
}

@test "integration: SELECT with escaped quotes" {
    sql=$(mq -n select ":O'Brien" as name)
    run mysql ${MYSQL_TEST_OPTIONS:-} -e "$sql"
    [ "$status" -eq 0 ]
}

@test "integration: SELECT with comparison operators" {
    sql=$(mq -n select 1 where 1 %eq 1)
    run mysql ${MYSQL_TEST_OPTIONS:-} -e "$sql"
    [ "$status" -eq 0 ]
}

@test "integration: SELECT with IN clause" {
    sql=$(mq -n select 1 where :a %in :a :b :c)
    run mysql ${MYSQL_TEST_OPTIONS:-} -e "$sql"
    [ "$status" -eq 0 ]
}

@test "integration: SELECT with NOW()" {
    sql=$(mq -n select %now as curr_time)
    run mysql ${MYSQL_TEST_OPTIONS:-} -e "$sql"
    [ "$status" -eq 0 ]
}

@test "integration: SELECT with RAND()" {
    sql=$(mq -n select %rand as random_value)
    run mysql ${MYSQL_TEST_OPTIONS:-} -e "$sql"
    [ "$status" -eq 0 ]
}

@test "integration: SELECT with JSON extract" {
    sql=$(mq -n select %json col from '(select' :'{\"name\":\"test\"}' as 'col)' t)
    run mysql ${MYSQL_TEST_OPTIONS:-} -e "$sql"
    [ "$status" -eq 0 ]
}

@test "integration: SELECT with multiple operators" {
    sql=$(mq -n select 1 where 1 %gte 0 and 1 %lte 2 and 1 %ne 0)
    run mysql ${MYSQL_TEST_OPTIONS:-} -e "$sql"
    [ "$status" -eq 0 ]
}

@test "integration: SELECT with greater/less than" {
    sql=$(mq -n select 1 where 5 %gt 3 and 3 %lt 5)
    run mysql ${MYSQL_TEST_OPTIONS:-} -e "$sql"
    [ "$status" -eq 0 ]
}

# Test that SQL injection attempts are properly escaped

@test "integration: SQL injection via string is escaped" {
    sql=$(mq -n select ":'; DROP TABLE users; --" as safe)
    run mysql ${MYSQL_TEST_OPTIONS:-} -e "$sql"
    [ "$status" -eq 0 ]
    # The query should return the escaped string, not execute DROP TABLE
    [[ "$output" == *"DROP TABLE"* ]]
}

@test "integration: SQL injection via equality is escaped" {
    sql=$(mq -n select 1 where 1=":' OR '1'='1")
    run mysql ${MYSQL_TEST_OPTIONS:-} -e "$sql"
    # This should parse correctly (the injection attempt is quoted)
    [ "$status" -eq 0 ]
}

@test "integration: special characters in IN clause" {
    sql=$(mq -n select 1 where :test %in ":it's" ":O'Reilly")
    run mysql ${MYSQL_TEST_OPTIONS:-} -e "$sql"
    [ "$status" -eq 0 ]
}
