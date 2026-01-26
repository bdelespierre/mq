#!/usr/bin/env bats

setup() {
    PROJECT_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
    source "$PROJECT_ROOT/lib/mysql-query/transform.sh"
}

# transform_string tests

@test "transform_string: wraps value in quotes" {
    run transform_string "hello"
    [ "$status" -eq 0 ]
    [ "$output" = "'hello'" ]
}

@test "transform_string: preserves trailing comma" {
    run transform_string "hello,"
    [ "$status" -eq 0 ]
    [ "$output" = "'hello'," ]
}

# transform_json tests

@test "transform_json: converts path to json_extract" {
    run transform_json "data.user.name"
    [ "$status" -eq 0 ]
    [ "$output" = "json_unquote(json_extract(data, '\$.user.name'))" ]
}

@test "transform_json: preserves trailing comma" {
    run transform_json "data.field,"
    [ "$status" -eq 0 ]
    [ "$output" = "json_unquote(json_extract(data, '\$.field'))," ]
}

# transform_equality tests

@test "transform_equality: converts x=:val to x='val'" {
    run transform_equality "email=:test@example.com"
    [ "$status" -eq 0 ]
    [ "$output" = "email='test@example.com'" ]
}

@test "transform_equality: preserves trailing comma" {
    run transform_equality "name=:john,"
    [ "$status" -eq 0 ]
    [ "$output" = "name='john'," ]
}

# transform_alias tests

@test "transform_alias: %a becomes *" {
    run transform_alias "%a"
    [ "$status" -eq 0 ]
    [ "$output" = "*" ]
}

@test "transform_alias: %all becomes *" {
    run transform_alias "%all"
    [ "$status" -eq 0 ]
    [ "$output" = "*" ]
}

@test "transform_alias: %c becomes count(*)" {
    run transform_alias "%c"
    [ "$status" -eq 0 ]
    [ "$output" = "count(*)" ]
}

@test "transform_alias: %count becomes count(*)" {
    run transform_alias "%count"
    [ "$status" -eq 0 ]
    [ "$output" = "count(*)" ]
}

@test "transform_alias: %r becomes rand()" {
    run transform_alias "%r"
    [ "$status" -eq 0 ]
    [ "$output" = "rand()" ]
}

@test "transform_alias: %rand becomes rand()" {
    run transform_alias "%rand"
    [ "$status" -eq 0 ]
    [ "$output" = "rand()" ]
}

@test "transform_alias: unknown alias returns error" {
    run transform_alias "%unknown"
    [ "$status" -eq 1 ]
}

# transform_operator tests

@test "transform_operator: %eq becomes =" {
    run transform_operator "%eq"
    [ "$status" -eq 0 ]
    [ "$output" = "=" ]
}

@test "transform_operator: %ne becomes <>" {
    run transform_operator "%ne"
    [ "$status" -eq 0 ]
    [ "$output" = "<>" ]
}

@test "transform_operator: %gt becomes >" {
    run transform_operator "%gt"
    [ "$status" -eq 0 ]
    [ "$output" = ">" ]
}

@test "transform_operator: %gte becomes >=" {
    run transform_operator "%gte"
    [ "$status" -eq 0 ]
    [ "$output" = ">=" ]
}

@test "transform_operator: %lt becomes <" {
    run transform_operator "%lt"
    [ "$status" -eq 0 ]
    [ "$output" = "<" ]
}

@test "transform_operator: %lte becomes <=" {
    run transform_operator "%lte"
    [ "$status" -eq 0 ]
    [ "$output" = "<=" ]
}

@test "transform_operator: unknown operator returns error" {
    run transform_operator "%unknown"
    [ "$status" -eq 1 ]
}

# process_argument tests

@test "process_argument: passthrough sets shift_count=1" {
    local out="" shift_count=""
    process_argument out shift_count hello
    [ "$out" = "hello" ]
    [ "$shift_count" -eq 1 ]
}

@test "process_argument: %string sets shift_count=2" {
    local out="" shift_count=""
    process_argument out shift_count %string hello
    [ "$out" = "'hello'" ]
    [ "$shift_count" -eq 2 ]
}

@test "process_argument: %json sets shift_count=2" {
    local out="" shift_count=""
    process_argument out shift_count %json data.name
    [ "$out" = "json_unquote(json_extract(data, '\$.name'))" ]
    [ "$shift_count" -eq 2 ]
}

# build_query tests

@test "build_query: simple select" {
    local sql="" vertical=""
    build_query sql vertical select %a from users
    [ "$sql" = "select * from users" ]
    [ "$vertical" -eq 0 ]
}

@test "build_query: select with string shorthand" {
    local sql="" vertical=""
    build_query sql vertical select %a from users where name=:john
    [ "$sql" = "select * from users where name='john'" ]
}

@test "build_query: select with explicit string" {
    local sql="" vertical=""
    build_query sql vertical select %a from users where name %eq %string john
    [ "$sql" = "select * from users where name = 'john'" ]
}

@test "build_query: select with comparison operator" {
    local sql="" vertical=""
    build_query sql vertical select %count from users where age %gt :18
    [ "$sql" = "select count(*) from users where age > '18'" ]
}

@test "build_query: select with json path" {
    local sql="" vertical=""
    build_query sql vertical select %json data.user.name from users
    [ "$sql" = "select json_unquote(json_extract(data, '\$.user.name')) from users" ]
}

@test "build_query: trailing + sets vertical=1" {
    local sql="" vertical=""
    build_query sql vertical select %a from users +
    [ "$sql" = "select * from users" ]
    [ "$vertical" -eq 1 ]
}

@test "build_query: + in middle is passed through" {
    local sql="" vertical=""
    build_query sql vertical select 1 + 1
    [ "$sql" = "select 1 + 1" ]
    [ "$vertical" -eq 0 ]
}
