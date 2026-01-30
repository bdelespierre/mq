#!/usr/bin/env bash
#
# log.bash - Logging and message output functions for mq
#

# Check if stderr is a terminal (for conditional coloring)
_log_color() {
    [[ -t 2 ]]
}

debug() {
    [[ "${DEBUG:-0}" == "1" ]] || return 0
    if _log_color; then
        >&2 echo -e "\e[33m[debug]\e[0m $*"
    else
        >&2 echo "[debug] $*"
    fi
}

info() {
    if _log_color; then
        >&2 echo -e "\e[1;34m==>\e[0m $*"
    else
        >&2 echo "==> $*"
    fi
}

warn() {
    [[ "${QUIET:-0}" == "1" ]] && return 0
    if _log_color; then
        >&2 echo -e "\e[1;33mwarning:\e[0m $*"
    else
        >&2 echo "warning: $*"
    fi
}

error() {
    if _log_color; then
        >&2 echo -e "\e[1;31merror:\e[0m $*"
    else
        >&2 echo "error: $*"
    fi
}
