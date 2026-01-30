#!/usr/bin/env bash
#
# transform.sh - Argument transformation functions for mq
#

# Transform %json a.b.c to json_unquote(json_extract(a, '$.b.c'))
# Transform %json a to json_unquote(json_extract(a, '$'))
transform_json() {
    local arg="${1%%,}"
    local column="${arg%%.*}"
    local result
    if [[ "$arg" == *"."* ]]; then
        result="json_unquote(json_extract(${column}, '\$.${arg#*.}'))"
    else
        result="json_unquote(json_extract(${column}, '\$'))"
    fi
    [[ "$1" == *, ]] && result+=","
    printf '%s' "$result"
}

# Transform value to 'value' (quoted string)
# Escapes single quotes: ' → ''
transform_string() {
    local arg="${1%%,}"
    local escaped="${arg//\'/\'\'}"
    local result="'${escaped}'"
    [[ "$1" == *, ]] && result+=","
    printf '%s' "$result"
}

# Transform x=:value to x='value' (equality with string)
# Escapes single quotes: ' → ''
transform_equality() {
    local arg="${1%%,}"
    local left="${arg%%=:*}"
    local right="${arg##*=:}"
    local escaped="${right//\'/\'\'}"
    local result="${left}='${escaped}'"
    [[ "$1" == *, ]] && result+=","
    printf '%s' "$result"
}

# Transform alias to its SQL equivalent
# Returns: the SQL equivalent, or empty string if not an alias
transform_alias() {
    case "$1" in
        %a|%all)   printf '*' ;;
        %c|%count) printf 'count(*)' ;;
        %r|%rand)  printf 'rand()' ;;
        %now)      printf 'now()' ;;
        *)         return 1 ;;
    esac
}

# Transform aggregate function: %sum col → SUM(col)
transform_aggregate() {
    local func="$1"
    local arg="${2%%,}"
    local result="${func}(${arg})"
    [[ "$2" == *, ]] && result+=","
    printf '%s' "$result"
}

# Transform %in :a :b :c to IN ('a', 'b', 'c')
# Args: values (without : prefix)
# Output: IN ('a', 'b', 'c')
transform_in() {
    local result="IN ("
    local first=1 val escaped
    for val in "$@"; do
        escaped="${val//\'/\'\'}"
        if [[ $first -eq 1 ]]; then
            first=0
        else
            result+=", "
        fi
        result+="'${escaped}'"
    done
    result+=")"
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

    local arg="$1"
    local trailing_comma=""

    # Handle standalone comma - pass through unchanged
    if [[ "$arg" == "," ]]; then
        _output=","
        return 0
    fi

    # Extract trailing comma if present (for pattern matching)
    if [[ "$arg" == *, ]]; then
        trailing_comma=","
        arg="${arg%,}"
    fi

    case "$arg" in
        %j|%json)
            if [[ -z "$2" ]]; then
                >&2 echo "error: $arg requires an argument"
                return 1
            fi
            _output=$(transform_json "$2")
            _shift_count=2
            ;;
        %s|%str|%string)
            if [[ -z "$2" ]]; then
                >&2 echo "error: $arg requires an argument"
                return 1
            fi
            _output=$(transform_string "$2")
            _shift_count=2
            ;;
        %a|%all|%c|%count|%r|%rand|%now)
            _output=$(transform_alias "$arg")
            _output+="$trailing_comma"
            ;;
        %sum|%avg|%min|%max)
            if [[ -z "$2" ]]; then
                >&2 echo "error: $arg requires an argument"
                return 1
            fi
            _output=$(transform_aggregate "${arg#%}" "$2")
            _shift_count=2
            ;;
        %eq|%ne|%gt|%gte|%lt|%lte)
            _output=$(transform_operator "$arg")
            # Operators don't preserve trailing comma (invalid SQL)
            ;;
        %in)
            # Collect all following :value arguments
            shift
            if [[ $# -eq 0 || "$1" != :* ]]; then
                >&2 echo "error: %in requires at least one :value argument"
                return 1
            fi
            local -a in_values=()
            local val
            while [[ $# -gt 0 && "$1" == :* ]]; do
                val="${1:1}"   # Strip leading colon
                val="${val%,}" # Strip trailing comma if present
                in_values+=("$val")
                shift
            done
            _output=$(transform_in "${in_values[@]}")
            _shift_count=$((1 + ${#in_values[@]}))
            ;;
        :*)
            # :value -> 'value'
            _output=$(transform_string "${arg:1}")
            _output+="$trailing_comma"
            ;;
        *=:*)
            # x=:value -> x='value'
            _output=$(transform_equality "$arg")
            _output+="$trailing_comma"
            ;;
        *)
            # Pass through unchanged (preserve trailing comma)
            _output="$arg$trailing_comma"
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
        if ! process_argument result shift_count "$@"; then
            return 1
        fi
        query+=("$result")

        shift "$shift_count"
    done

    _output="${query[*]}"
}
