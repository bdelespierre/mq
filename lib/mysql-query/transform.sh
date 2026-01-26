#!/usr/bin/env bash
#
# transform.sh - Argument transformation functions for mysql-query
#

# Transform %json a.b.c to json_unquote(json_extract(a, '$.b.c'))
transform_json() {
    local arg="${1%%,}"
    local result="json_unquote(json_extract(${arg%%.*}, '\$.${arg#*.}'))"
    [[ "$1" == *, ]] && result+=","
    printf '%s' "$result"
}

# Transform value to 'value' (quoted string)
transform_string() {
    local arg="${1%%,}"
    local result="'${arg}'"
    [[ "$1" == *, ]] && result+=","
    printf '%s' "$result"
}

# Transform x=:value to x='value' (equality with string)
transform_equality() {
    local arg="${1%%,}"
    local left="${arg%%=:*}"
    local right="${arg##*=:}"
    local result="${left}='${right}'"
    [[ "$1" == *, ]] && result+=","
    printf '%s' "$result"
}

# Transform alias to its SQL equivalent
# Returns: the SQL equivalent, or empty string if not an alias
transform_alias() {
    local arg="$1"
    local result=""

    case "$arg" in
        %a|%all)   result="*" ;;
        %c|%count) result="count(*)" ;;
        %r|%rand)  result="rand()" ;;
        *)         return 1 ;;
    esac

    [[ "$arg" == *, ]] && result+=","
    printf '%s' "$result"
}

# Transform operator alias to SQL operator
# Returns: the SQL operator, or empty string if not an operator
transform_operator() {
    case "$1" in
        %eq)  printf '=' ;;
        %ne)  printf '<>' ;;
        %gt)  printf '>' ;;
        %gte) printf '>=' ;;
        %lt)  printf '<' ;;
        %lte) printf '<=' ;;
        *)    return 1 ;;
    esac
}

process_argument() {
    local -n _output="$1"; _output=""
    local -n _shift_count="$2"; _shift_count=1
    shift 2

    case "$1" in
        %j|%json)
            _output=$(transform_json "$2")
            _shift_count=2
            ;;
        %s|%str|%string)
            _output=$(transform_string "$2")
            _shift_count=2
            ;;
        %a|%all|%c|%count|%r|%rand)
            _output=$(transform_alias "$1")
            ;;
        %eq|%ne|%gt|%gte|%lt|%lte)
            _output=$(transform_operator "$1")
            ;;
        :*)
            # :value -> 'value'
            _output=$(transform_string "${1:1}")
            ;;
        *=:*)
            # x=:value -> x='value'
            _output=$(transform_equality "$1")
            ;;
        *)
            # Pass through unchanged
            _output="$1"
            ;;
    esac
}

# Build the complete query from arguments
# Args: all query arguments
# Output: the SQL query string
# Returns: 0 if normal, 1 if vertical format requested (trailing +)
build_query() {
    local -n _output="$1"; _output=""
    local -n _vertical="$2"; _vertical=0
    shift 2

    local -a query=()
    while [[ $# -gt 0 ]]; do
        # Handle trailing + for vertical format
        if [[ "$1" == "+" && $# -eq 1 ]]; then
            _vertical=1
            shift
            continue
        fi

        local result="" shift_count=""
        process_argument result shift_count "$@"
        query+=("$result")

        shift "$shift_count"
    done

    _output="${query[*]}"
}
