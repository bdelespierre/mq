# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

mq.bash is a Bash CLI tool that provides a convenient wrapper around the MySQL/MariaDB client with argument expansion, SQL shorthand helpers, and output formatting options.

## Usage

```bash
bin/mq -o database=mydb select %count from users where birthdate %gt :2000-01-01
```

## Project Structure

```
bin/
  mq        # Main executable (usage, option parsing, main)
lib/mq/
  log.bash             # Logging and message output helpers
  transform.bash       # Argument transformation functions
  format.bash          # Output format filters (CSV, JSON)
tests/
  cli.bats             # CLI integration tests
  transform.bats       # BATS tests for transform functions
  format.bats          # BATS tests for format filters
  log.bats             # BATS tests for logging functions
```

## Commands

```bash
make test             # Run tests (requires bats)
make install          # Install to ~/.local (default)
make install-system   # Install to /usr/local (requires sudo)
make uninstall        # Remove local installation
make uninstall-system # Remove system installation
```

## Architecture

**bin/mq** - Entry point with:
- `usage()` - Help text
- `set_format()` - Converts format option to MySQL/MariaDB flags
- `execute_query()` - Runs query through mysql and pager
- `main()` - Option parsing with getopt, orchestrates the flow

**lib/mq/log.bash** - Logging helpers:
- `debug()` - Yellow `[debug]` prefix, conditional on `DEBUG=1`
- `info()` - Blue `==>` prefix, user-facing confirmations
- `warn()` - Yellow `warning:` prefix, suppressed by `QUIET=1`
- `error()` - Red `error:` prefix, does NOT exit (caller controls flow)

**lib/mq/transform.bash** - Query building:
- `transform_json()` - `%json a.b.c` → `json_unquote(json_extract(a, '$.b.c'))`
- `transform_string()` - Wraps value in single quotes
- `transform_equality()` - `x=:val` → `x='val'`
- `transform_alias()` - `%all`→`*`, `%count`→`count(*)`, `%rand`→`rand()`
- `transform_operator()` - `%eq/%ne/%gt/%gte/%lt/%lte` → SQL operators
- `process_argument()` - Routes argument to transformer, returns args consumed (1 or 2)
- `build_query()` - Iterates all arguments, returns SQL string (exit 1 if trailing `+`)

**lib/mq/format.bash** - Output format filters:
- `tsv_to_csv()` - Converts MySQL batch TSV to RFC 4180 CSV
- `tsv_to_json()` - Converts MySQL batch TSV to JSON array of objects

Output formats: `tsv` (default), `table`, `vertical`, `html`, `xml`, `csv`, `json`

## Common Usages

### Basic Queries
```bash
# Select all from table
mq -o database=mydb select %all from users

# Count rows
mq -o database=mydb select %count from orders

# Random row
mq -o database=mydb select %all from products order by %rand limit 1
```

### String Values (`:value` shorthand)
```bash
# Where clause with string value
mq select %all from users where email=:john@example.com

# Multiple string values
mq select %all from users where status=:active and role=:admin

# Explicit %string for clarity
mq select %all from users where name %eq %string "John Doe"
```

### Comparison Operators
```bash
# Greater than
mq select %all from orders where total %gt :100

# Date comparisons
mq select %count from users where created_at %gte :2024-01-01

# Not equal
mq select %all from products where status %ne :discontinued
```

### IN Clauses
```bash
# Multiple values with %in
mq select %all from users where role %in :admin :moderator :editor
```

### JSON Extraction
```bash
# Extract JSON field: json_unquote(json_extract(data, '$.name'))
mq select %json data.name from users

# Nested JSON path
mq select %json metadata.author.email from posts
```

### Output Formatting
```bash
# Table format
mq -f table select %all from users

# Vertical format (like \G)
mq select %all from users where id=:1 +

# Pipe through pager
PAGER=less mq -f table select %all from large_table
```

### Dry Run and Debugging
```bash
# Show query without executing
mq -n select %all from users where email=:test@example.com

# Quiet mode (suppress query echo)
mq -q select %count from users
```

### Configuration
```bash
# Use project-local config
echo 'MYSQL_OPTIONS+=(--database=mydb --host=localhost)' > .mqrc

# Override global config location
MQRC=/path/to/config mq select %count from users
```

## Conventions

### Code Style
- Use `set -euo pipefail` at script entry points
- Use lowercase for local variables, UPPERCASE for globals/exports
- Quote all variable expansions: `"$var"` not `$var`
- Use `[[ ]]` for conditionals, not `[ ]`
- Use `$(...)` for command substitution, not backticks

### Function Patterns
- Transform functions take input and print output via `printf '%s'`
- Use nameref (`local -n`) for output parameters in complex functions
- Return non-zero for errors, echo error messages to stderr

### Testing
- Tests use BATS (Bash Automated Testing System)
- Test files live in `tests/` with `.bats` extension
- Source the library being tested at the top of test file
- Use `run` to capture command output and status
- Assert with `[[ "$status" -eq 0 ]]` and `[[ "$output" == "expected" ]]`

### Argument Processing
- Arguments with trailing commas preserve the comma in output
- `:value` is shorthand for `%string value`
- `%` prefix indicates a special token (alias, operator, or type)
- `+` as final argument triggers vertical output format
