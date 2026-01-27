# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

mq.bash is a Bash CLI tool that provides a convenient wrapper around the MySQL client with argument expansion, SQL shorthand helpers, and output formatting options.

## Usage

```bash
bin/mq -o database=mydb select %count from users where birthdate %gt :2000-01-01
```

## Project Structure

```
bin/
  mq        # Main executable (usage, option parsing, main)
lib/mq/
  transform.sh       # Argument transformation functions
tests/
  transform.bats     # BATS tests for transform functions
```

## Commands

```bash
make test      # Run tests (requires bats)
make install   # Install to /usr/local (or PREFIX=~/.local)
make uninstall # Remove installed files
```

## Architecture

**bin/mq** - Entry point with:
- `usage()` - Help text
- `apply_format()` - Converts format option to MySQL flags
- `execute_query()` - Runs query through mysql and pager
- `main()` - Option parsing with getopt, orchestrates the flow

**lib/mq/transform.sh** - Query building:
- `transform_json()` - `%json a.b.c` → `json_unquote(json_extract(a, '$.b.c'))`
- `transform_string()` - Wraps value in single quotes
- `transform_equality()` - `x=:val` → `x='val'`
- `transform_alias()` - `%all`→`*`, `%count`→`count(*)`, `%rand`→`rand()`
- `transform_operator()` - `%eq/%ne/%gt/%gte/%lt/%lte` → SQL operators
- `process_argument()` - Routes argument to transformer, returns args consumed (1 or 2)
- `build_query()` - Iterates all arguments, returns SQL string (exit 1 if trailing `+`)

Output formats: `tsv` (default), `table`, `vertical`, `html`, `xml`

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
