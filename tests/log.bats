#!/usr/bin/env bats

setup() {
    PROJECT_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
    source "$PROJECT_ROOT/lib/mq/log.bash"
}

# error

@test "error: outputs message with error: prefix" {
    run error "something went wrong"
    [ "$status" -eq 0 ]
    [ "$output" = "error: something went wrong" ]
}

@test "error: does not exit" {
    run bash -c 'source "$1" && error "test" && echo "still running"' -- "$PROJECT_ROOT/lib/mq/log.bash"
    [ "$status" -eq 0 ]
    [[ "$output" == *"still running"* ]]
}

# info

@test "info: outputs message with ==> prefix" {
    run info "task completed"
    [ "$status" -eq 0 ]
    [ "$output" = "==> task completed" ]
}

# warn

@test "warn: outputs message with warning: prefix" {
    export QUIET=0
    run warn "be careful"
    [ "$status" -eq 0 ]
    [ "$output" = "warning: be careful" ]
}

@test "warn: suppressed when QUIET=1" {
    export QUIET=1
    run warn "should not appear"
    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

# debug

@test "debug: suppressed when DEBUG is not 1" {
    export DEBUG=0
    run debug "hidden message"
    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

@test "debug: outputs when DEBUG=1" {
    export DEBUG=1
    run debug "visible message"
    [ "$status" -eq 0 ]
    [ "$output" = "[debug] visible message" ]
}
