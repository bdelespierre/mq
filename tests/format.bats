#!/usr/bin/env bats

setup() {
    PROJECT_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
    source "$PROJECT_ROOT/lib/mq/format.bash"
}

# Basic conversion

@test "tsv_to_csv: single column" {
    result=$(printf 'value\n' | tsv_to_csv)
    [[ "$result" == "value" ]]
}

@test "tsv_to_csv: two columns" {
    result=$(printf 'a\tb\n' | tsv_to_csv)
    [[ "$result" == "a,b" ]]
}

@test "tsv_to_csv: header plus data rows" {
    result=$(printf 'name\temail\nJohn\tjohn@test.com\nJane\tjane@test.com\n' | tsv_to_csv)
    IFS=$'\n' read -r -d '' -a lines <<< "$result" || true
    [[ "${lines[0]}" == "name,email" ]]
    [[ "${lines[1]}" == "John,john@test.com" ]]
    [[ "${lines[2]}" == "Jane,jane@test.com" ]]
}

@test "tsv_to_csv: three columns" {
    result=$(printf 'id\tname\tage\n1\tAlice\t30\n' | tsv_to_csv)
    IFS=$'\n' read -r -d '' -a lines <<< "$result" || true
    [[ "${lines[0]}" == "id,name,age" ]]
    [[ "${lines[1]}" == "1,Alice,30" ]]
}

# Empty input

@test "tsv_to_csv: empty input produces no output" {
    result=$(printf '' | tsv_to_csv)
    [[ "$result" == "" ]]
}

# RFC 4180 quoting

@test "tsv_to_csv: field with comma gets quoted" {
    result=$(printf 'hello, world\ttest\n' | tsv_to_csv)
    [[ "$result" == '"hello, world",test' ]]
}

@test "tsv_to_csv: field with double quote gets escaped" {
    result=$(printf 'say "hi"\ttest\n' | tsv_to_csv)
    [[ "$result" == '"say ""hi""",test' ]]
}

@test "tsv_to_csv: plain field without special chars is not quoted" {
    result=$(printf 'hello\tworld\n' | tsv_to_csv)
    [[ "$result" == "hello,world" ]]
}

# MySQL escape handling

@test "tsv_to_csv: NULL becomes empty" {
    result=$(printf 'name\t\\N\n' | tsv_to_csv)
    [[ "$result" == "name," ]]
}

@test "tsv_to_csv: escaped backslash" {
    result=$(printf 'path\\\\file\tother\n' | tsv_to_csv)
    [[ "$result" == 'path\file,other' ]]
}

@test "tsv_to_csv: escaped newline gets quoted" {
    result=$(printf 'line1\\nline2\tother\n' | tsv_to_csv)
    expected=$(printf '"line1\nline2",other')
    [[ "$result" == "$expected" ]]
}

@test "tsv_to_csv: escaped tab in data" {
    result=$(printf 'col1\\tcol2\tother\n' | tsv_to_csv)
    expected=$(printf 'col1\tcol2,other')
    [[ "$result" == "$expected" ]]
}

# Edge cases

@test "tsv_to_csv: empty fields" {
    result=$(printf '\t\tvalue\n' | tsv_to_csv)
    [[ "$result" == ",,value" ]]
}

@test "tsv_to_csv: field with only comma" {
    result=$(printf ',\tother\n' | tsv_to_csv)
    [[ "$result" == '",",other' ]]
}

@test "tsv_to_csv: multiple NULLs" {
    result=$(printf '\\N\t\\N\t\\N\n' | tsv_to_csv)
    [[ "$result" == ",," ]]
}

# =============================================================================
# tsv_to_json tests
# =============================================================================

# Basic conversion

@test "tsv_to_json: single column single row" {
    result=$(printf 'name\nAlice\n' | tsv_to_json)
    [[ "$result" == '[{"name":"Alice"}]' ]]
}

@test "tsv_to_json: two columns single row" {
    result=$(printf 'name\temail\nAlice\talice@test.com\n' | tsv_to_json)
    [[ "$result" == '[{"name":"Alice","email":"alice@test.com"}]' ]]
}

@test "tsv_to_json: multiple rows" {
    result=$(printf 'id\tname\n1\tAlice\n2\tBob\n' | tsv_to_json)
    [[ "$result" == '[{"id":"1","name":"Alice"},{"id":"2","name":"Bob"}]' ]]
}

@test "tsv_to_json: three columns" {
    result=$(printf 'id\tname\tage\n1\tAlice\t30\n' | tsv_to_json)
    [[ "$result" == '[{"id":"1","name":"Alice","age":"30"}]' ]]
}

# Empty / no data

@test "tsv_to_json: empty input produces empty array" {
    result=$(printf '' | tsv_to_json)
    [[ "$result" == '[]' ]]
}

@test "tsv_to_json: header only produces empty array" {
    result=$(printf 'name\temail\n' | tsv_to_json)
    [[ "$result" == '[]' ]]
}

# NULL handling

@test "tsv_to_json: NULL becomes json null" {
    result=$(printf 'name\tage\nAlice\t\\N\n' | tsv_to_json)
    [[ "$result" == '[{"name":"Alice","age":null}]' ]]
}

@test "tsv_to_json: multiple NULLs" {
    result=$(printf 'a\tb\tc\n\\N\t\\N\t\\N\n' | tsv_to_json)
    [[ "$result" == '[{"a":null,"b":null,"c":null}]' ]]
}

@test "tsv_to_json: NULL in first column" {
    result=$(printf 'name\tval\n\\N\thello\n' | tsv_to_json)
    [[ "$result" == '[{"name":null,"val":"hello"}]' ]]
}

# JSON string escaping

@test "tsv_to_json: double quote in value is escaped" {
    result=$(printf 'val\nsay "hi"\n' | tsv_to_json)
    [[ "$result" == '[{"val":"say \"hi\""}]' ]]
}

@test "tsv_to_json: backslash in value is escaped" {
    result=$(printf 'path\nC:\\\\Users\n' | tsv_to_json)
    [[ "$result" == '[{"path":"C:\\Users"}]' ]]
}

@test "tsv_to_json: newline in value is escaped" {
    result=$(printf 'text\nline1\\nline2\n' | tsv_to_json)
    [[ "$result" == '[{"text":"line1\nline2"}]' ]]
}

@test "tsv_to_json: tab in value is escaped" {
    result=$(printf 'text\ncol1\\tcol2\n' | tsv_to_json)
    [[ "$result" == '[{"text":"col1\tcol2"}]' ]]
}

# Edge cases

@test "tsv_to_json: empty string value" {
    result=$(printf 'a\tb\n\tworld\n' | tsv_to_json)
    [[ "$result" == '[{"a":"","b":"world"}]' ]]
}

@test "tsv_to_json: values are always strings not numbers" {
    result=$(printf 'zip\n02139\n' | tsv_to_json)
    [[ "$result" == '[{"zip":"02139"}]' ]]
}

@test "tsv_to_json: output is valid for jq" {
    if ! command -v jq &>/dev/null; then
        skip "jq not installed"
    fi
    result=$(printf 'id\tname\n1\tAlice\n2\tBob\n' | tsv_to_json | jq -r '.[0].name')
    [[ "$result" == "Alice" ]]
}
