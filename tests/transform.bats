#!/usr/bin/env bats

setup() {
    PROJECT_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
    source "$PROJECT_ROOT/lib/mq/transform.sh"
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

@test "transform_string: escapes single quotes" {
    run transform_string "O'Brien"
    [ "$status" -eq 0 ]
    [ "$output" = "'O''Brien'" ]
}

@test "transform_string: escapes multiple single quotes" {
    run transform_string "it's a 'test'"
    [ "$status" -eq 0 ]
    [ "$output" = "'it''s a ''test'''" ]
}

# transform_json tests

@test "transform_json: converts path to json_extract" {
    run transform_json "data.user.name"
    [ "$status" -eq 0 ]
    [ "$output" = "json_unquote(json_extract(data, '\$.user.name'))" ]
}

@test "transform_json: single-level path (no dot) extracts root" {
    run transform_json "data"
    [ "$status" -eq 0 ]
    [ "$output" = "json_unquote(json_extract(data, '\$'))" ]
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

@test "transform_equality: escapes single quotes in value" {
    run transform_equality "name=:O'Brien"
    [ "$status" -eq 0 ]
    [ "$output" = "name='O''Brien'" ]
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

@test "transform_alias: %now becomes now()" {
    run transform_alias "%now"
    [ "$status" -eq 0 ]
    [ "$output" = "now()" ]
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

# transform_in tests

@test "transform_in: single value" {
    run transform_in "a"
    [ "$status" -eq 0 ]
    [ "$output" = "IN ('a')" ]
}

@test "transform_in: multiple values" {
    run transform_in "a" "b" "c"
    [ "$status" -eq 0 ]
    [ "$output" = "IN ('a', 'b', 'c')" ]
}

@test "transform_in: escapes single quotes" {
    run transform_in "O'Brien" "test"
    [ "$status" -eq 0 ]
    [ "$output" = "IN ('O''Brien', 'test')" ]
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

@test "process_argument: %json without argument returns error" {
    local out="" shift_count=""
    run bash -c 'source "$1" && process_argument out shift_count %json' -- "$PROJECT_ROOT/lib/mq/transform.sh"
    [ "$status" -eq 1 ]
    [ "$output" = "error: %json requires an argument" ]
}

@test "process_argument: %string without argument returns error" {
    local out="" shift_count=""
    run bash -c 'source "$1" && process_argument out shift_count %string' -- "$PROJECT_ROOT/lib/mq/transform.sh"
    [ "$status" -eq 1 ]
    [ "$output" = "error: %string requires an argument" ]
}

@test "process_argument: %j without argument returns error" {
    local out="" shift_count=""
    run bash -c 'source "$1" && process_argument out shift_count %j' -- "$PROJECT_ROOT/lib/mq/transform.sh"
    [ "$status" -eq 1 ]
    [ "$output" = "error: %j requires an argument" ]
}

@test "process_argument: %s without argument returns error" {
    local out="" shift_count=""
    run bash -c 'source "$1" && process_argument out shift_count %s' -- "$PROJECT_ROOT/lib/mq/transform.sh"
    [ "$status" -eq 1 ]
    [ "$output" = "error: %s requires an argument" ]
}

@test "process_argument: %in collects multiple values" {
    local out="" shift_count=""
    process_argument out shift_count %in :a :b :c
    [ "$out" = "IN ('a', 'b', 'c')" ]
    [ "$shift_count" -eq 4 ]
}

@test "process_argument: %in stops at non-colon argument" {
    local out="" shift_count=""
    process_argument out shift_count %in :a :b from
    [ "$out" = "IN ('a', 'b')" ]
    [ "$shift_count" -eq 3 ]
}

@test "process_argument: %in without values returns error" {
    local out="" shift_count=""
    run bash -c 'source "$1" && process_argument out shift_count %in from' -- "$PROJECT_ROOT/lib/mq/transform.sh"
    [ "$status" -eq 1 ]
    [ "$output" = "error: %in requires at least one :value argument" ]
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

@test "build_query: select with in operator" {
    local sql="" vertical=""
    build_query sql vertical select %a from users where status %in :active :pending :review
    [ "$sql" = "select * from users where status IN ('active', 'pending', 'review')" ]
}

@test "build_query: insert with now()" {
    local sql="" vertical=""
    build_query sql vertical insert into logs set created_at %eq %now
    [ "$sql" = "insert into logs set created_at = now()" ]
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

@test "build_query: trailing %json without argument returns error" {
    run bash -c 'source "$1" && build_query sql vertical select %json' -- "$PROJECT_ROOT/lib/mq/transform.sh"
    [ "$status" -eq 1 ]
    [ "$output" = "error: %json requires an argument" ]
}

@test "build_query: trailing %string without argument returns error" {
    run bash -c 'source "$1" && build_query sql vertical select %string' -- "$PROJECT_ROOT/lib/mq/transform.sh"
    [ "$status" -eq 1 ]
    [ "$output" = "error: %string requires an argument" ]
}

# Edge case tests: empty strings

@test "edge case: transform_string with empty string" {
    run transform_string ""
    [ "$status" -eq 0 ]
    [ "$output" = "''" ]
}

@test "edge case: :empty string shorthand" {
    local out="" shift_count=""
    process_argument out shift_count ":"
    [ "$out" = "''" ]
}

@test "edge case: build_query with empty string value" {
    local sql="" vertical=""
    build_query sql vertical select %a from users where name=:
    [ "$sql" = "select * from users where name=''" ]
}

# Edge case tests: special characters

@test "edge case: string with spaces" {
    run transform_string "hello world"
    [ "$status" -eq 0 ]
    [ "$output" = "'hello world'" ]
}

@test "edge case: string with double quotes" {
    run transform_string 'say "hello"'
    [ "$status" -eq 0 ]
    [ "$output" = "'say \"hello\"'" ]
}

@test "edge case: string with backslash" {
    run transform_string 'path\to\file'
    [ "$status" -eq 0 ]
    [ "$output" = "'path\\to\\file'" ]
}

@test "edge case: string with semicolon (SQL injection attempt)" {
    run transform_string "value; DROP TABLE users;--"
    [ "$status" -eq 0 ]
    [ "$output" = "'value; DROP TABLE users;--'" ]
}

@test "edge case: string with SQL comment" {
    run transform_string "value'--comment"
    [ "$status" -eq 0 ]
    [ "$output" = "'value''--comment'" ]
}

@test "edge case: string with percent signs" {
    run transform_string "%test%"
    [ "$status" -eq 0 ]
    [ "$output" = "'%test%'" ]
}

@test "edge case: string with newline" {
    run transform_string $'line1\nline2'
    [ "$status" -eq 0 ]
    [ "$output" = $'\'line1\nline2\'' ]
}

@test "edge case: string with tab" {
    run transform_string $'col1\tcol2'
    [ "$status" -eq 0 ]
    [ "$output" = $'\'col1\tcol2\'' ]
}

@test "edge case: equality with special characters" {
    run transform_equality "name=:O'Reilly & Sons"
    [ "$status" -eq 0 ]
    [ "$output" = "name='O''Reilly & Sons'" ]
}

@test "edge case: transform_in with special characters" {
    run transform_in "it's" "a \"test\"" "value;drop"
    [ "$status" -eq 0 ]
    [ "$output" = "IN ('it''s', 'a \"test\"', 'value;drop')" ]
}

# Edge case tests: numeric values

@test "edge case: string with numeric value" {
    run transform_string "12345"
    [ "$status" -eq 0 ]
    [ "$output" = "'12345'" ]
}

@test "edge case: string with negative number" {
    run transform_string "-42.5"
    [ "$status" -eq 0 ]
    [ "$output" = "'-42.5'" ]
}

# Edge case tests: JSON paths

@test "edge case: json with array index" {
    run transform_json "data.items[0].name"
    [ "$status" -eq 0 ]
    [ "$output" = "json_unquote(json_extract(data, '\$.items[0].name'))" ]
}

@test "edge case: json with nested arrays" {
    run transform_json "data.a.b.c.d.e"
    [ "$status" -eq 0 ]
    [ "$output" = "json_unquote(json_extract(data, '\$.a.b.c.d.e'))" ]
}

# Edge case tests: missing arguments

@test "edge case: %in with no values returns error" {
    run bash -c 'source "$1" && build_query sql vertical select %a from users where id %in' -- "$PROJECT_ROOT/lib/mq/transform.sh"
    [ "$status" -eq 1 ]
    [[ "$output" == *"error: %in requires"* ]]
}

# Edge case tests: passthrough

@test "edge case: SQL keywords pass through unchanged" {
    local sql="" vertical=""
    build_query sql vertical SELECT DISTINCT name FROM users ORDER BY name ASC
    [ "$sql" = "SELECT DISTINCT name FROM users ORDER BY name ASC" ]
}

@test "edge case: numbers pass through unchanged" {
    local sql="" vertical=""
    build_query sql vertical select %a from users where id %eq 123
    [ "$sql" = "select * from users where id = 123" ]
}

@test "edge case: asterisk passes through" {
    local sql="" vertical=""
    build_query sql vertical select '*' from users
    [ "$sql" = "select * from users" ]
}

# Comma handling tests

@test "comma: standalone comma passes through" {
    local out="" shift_count=""
    process_argument out shift_count ","
    [ "$out" = "," ]
}

@test "comma: trailing comma on passthrough value" {
    local out="" shift_count=""
    process_argument out shift_count "a,"
    [ "$out" = "a," ]
}

@test "comma: trailing comma on alias %all" {
    local out="" shift_count=""
    process_argument out shift_count "%all,"
    [ "$out" = "*," ]
}

@test "comma: trailing comma on alias %count" {
    local out="" shift_count=""
    process_argument out shift_count "%count,"
    [ "$out" = "count(*)," ]
}

@test "comma: trailing comma on :value" {
    local out="" shift_count=""
    process_argument out shift_count ":hello,"
    [ "$out" = "'hello'," ]
}

@test "comma: trailing comma on equality" {
    local out="" shift_count=""
    process_argument out shift_count "name=:john,"
    [ "$out" = "name='john'," ]
}

@test "comma: operator ignores trailing comma" {
    local out="" shift_count=""
    process_argument out shift_count "%eq,"
    [ "$out" = "=" ]
}

@test "comma: %in with comma-separated values" {
    local out="" shift_count=""
    process_argument out shift_count %in :a, :b, :c
    [ "$out" = "IN ('a', 'b', 'c')" ]
    [ "$shift_count" -eq 4 ]
}

@test "comma: build_query with 'select a,b,c'" {
    local sql="" vertical=""
    build_query sql vertical select a,b,c from users
    [ "$sql" = "select a,b,c from users" ]
}

@test "comma: build_query with 'select a, b, c'" {
    local sql="" vertical=""
    build_query sql vertical select a, b, c from users
    [ "$sql" = "select a, b, c from users" ]
}

@test "comma: build_query with 'select a , b , c'" {
    local sql="" vertical=""
    build_query sql vertical select a , b , c from users
    [ "$sql" = "select a , b , c from users" ]
}

@test "comma: build_query with alias and trailing comma" {
    local sql="" vertical=""
    build_query sql vertical select %all, id from users
    [ "$sql" = "select *, id from users" ]
}

@test "comma: build_query with multiple aliases and commas" {
    local sql="" vertical=""
    build_query sql vertical select %count, %now, id from users
    [ "$sql" = "select count(*), now(), id from users" ]
}

@test "comma: build_query with :value and trailing comma" {
    local sql="" vertical=""
    build_query sql vertical select :hello, :world from dual
    [ "$sql" = "select 'hello', 'world' from dual" ]
}
