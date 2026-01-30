#!/usr/bin/env bash
#
# bookmark.bash - Named query bookmark management for mq
#

# Source logging helpers if not already available
if ! declare -F error &>/dev/null; then
    source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/log.bash"
fi

validate_bookmark_name() {
    local name="$1"
    if [[ ! "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        error "Invalid bookmark name: $name (only letters, digits, - and _ allowed)"
        exit 1
    fi
}

save_bookmark() {
    local name="$1" sql="$2"
    validate_bookmark_name "$name"
    mkdir -p "$MQ_QUERIES_DIR"
    printf '%s\n' "$sql" > "$MQ_QUERIES_DIR/$name.sql"
    info "Saved bookmark '$name'"
}

list_bookmarks() {
    if [[ ! -d "$MQ_QUERIES_DIR" ]]; then
        info "No saved bookmarks. Use --save NAME to bookmark a query."
        return 0
    fi
    local found=0 f
    for f in "$MQ_QUERIES_DIR"/*.sql; do
        [[ -f "$f" ]] || continue
        basename "$f" .sql
        found=1
    done
    if [[ "$found" -eq 0 ]]; then
        info "No saved bookmarks. Use --save NAME to bookmark a query."
    fi
}

show_bookmark() {
    local name="$1"
    validate_bookmark_name "$name"
    local file="$MQ_QUERIES_DIR/$name.sql"
    if [[ ! -f "$file" ]]; then
        error "Bookmark not found: $name"
        exit 1
    fi
    cat "$file"
}

delete_bookmark() {
    local name="$1"
    validate_bookmark_name "$name"
    local file="$MQ_QUERIES_DIR/$name.sql"
    if [[ ! -f "$file" ]]; then
        error "Bookmark not found: $name"
        exit 1
    fi
    rm "$file"
    info "Deleted bookmark '$name'"
}
