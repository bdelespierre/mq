# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

mysql-query.bash is a Bash CLI tool that provides a convenient wrapper around the MySQL client with argument expansion, SQL shorthand helpers, and output formatting options.

## Usage

```bash
bin/mysql-query -o database=mydb select %count from users where birthdate %gt :2000-01-01
```

## Project Structure

```
bin/
  mysql-query        # Main executable (usage, option parsing, main)
lib/mysql-query/
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

**bin/mysql-query** - Entry point with:
- `usage()` - Help text
- `apply_format()` - Converts format option to MySQL flags
- `execute_query()` - Runs query through mysql and pager
- `main()` - Option parsing with getopt, orchestrates the flow

**lib/mysql-query/transform.sh** - Query building:
- `transform_json()` - `%json a.b.c` → `json_unquote(json_extract(a, '$.b.c'))`
- `transform_string()` - Wraps value in single quotes
- `transform_equality()` - `x=:val` → `x='val'`
- `transform_alias()` - `%all`→`*`, `%count`→`count(*)`, `%rand`→`rand()`
- `transform_operator()` - `%eq/%ne/%gt/%gte/%lt/%lte` → SQL operators
- `process_argument()` - Routes argument to transformer, returns args consumed (1 or 2)
- `build_query()` - Iterates all arguments, returns SQL string (exit 1 if trailing `+`)

Output formats: `tsv` (default), `table`, `vertical`, `html`, `xml`
