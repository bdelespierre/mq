# mysql-query.bash

A Bash-based MySQL client wrapper with argument expansion and SQL shorthand helpers.

## Features

- SQL shorthand helpers for common patterns (strings, JSON paths, operators)
- Multiple output formats: TSV, table, vertical, HTML, XML
- Trailing `+` for vertical output (like MySQL's `\G`)
- Automatic query echo to stderr for debugging
- Pager support via `$PAGER` environment variable
- Global and project-local configuration files

## Installation

Clone the repository:

```bash
git clone <repository-url>
cd mysql-query.bash
```

Install using make (installs to `/usr/local`):

```bash
sudo make install
```

Or install to a custom location:
```bash
make install PREFIX=~/.local
```

Alternatively, add the `bin` directory to your PATH:

```bash
export PATH="$PATH:$(pwd)/bin"
```

Ensure MySQL client is installed:

```bash
mysql --version
```

## Uninstallation

```bash
sudo make uninstall
```

Or if installed with a custom prefix:
```bash
make uninstall PREFIX=~/.local
```

## Usage

```bash
# Basic query with string shorthand (:value becomes 'value')
mysql-query -o database=mydb select '*' from users where name=:john

# Count with comparison operator
mysql-query -o database=mydb select %count from users where age %gt :18

# Select all columns with alias
mysql-query -o database=mydb select %a from products where price %lte 99.99

# JSON path extraction
mysql-query -o database=mydb select %json settings.ui.dark_mode from users

# Vertical output with trailing +
mysql-query -o database=mydb select %a from users where id=:1 +

# Use with pager
PAGER=less mysql-query -o database=mydb select %a from large_table

# Table format output
mysql-query -o database=mydb -f table select %a from users
```

## Options Reference

| Option | Description |
|--------|-------------|
| `-h, --help` | Show help message |
| `-v, --version` | Show version and exit |
| `-o, --option NAME[=VALUE]` | Set MySQL client option (see `mysql --help`) |
| `-f, --format NAME` | Output format: `tsv` (default), `table`, `vertical`, `html`, `xml` |
| `-q, --quiet` | Suppress query echo to stderr |
| `-n, --dry-run` | Show query without executing |
| `-i, --input FILE` | Read query from file (use `-` for stdin) |

## Argument Shortcuts

| Shorthand | Expansion |
|-----------|-----------|
| `:value` `%s VALUE` `%string VALUE` | `'VALUE'` |
| `%j PATH` `%json PATH` | `json_unquote(json_extract(...))` |
| `%a` `%all` | `*` |
| `%c` `%count` | `COUNT(*)` |
| `%r` `%rand` | `RAND()` |
| `%now` | `NOW()` |
| `%eq` | `=` |
| `%ne` | `<>` |
| `%gt` | `>` |
| `%gte` | `>=` |
| `%lt` | `<` |
| `%lte` | `<=` |
| `%in :a :b :c` | `IN ('a', 'b', 'c')` |
| `+` (trailing) | Vertical output format |

## MySQL Options

Pass MySQL client options with `-o`:

```bash
# Connect to specific database
mysql-query -o database=mydb ...

# Connect to remote host
mysql-query -o host=db.example.com -o user=admin -o password=secret ...

# Use specific port
mysql-query -o port=3307 ...

# Use defaults file
mysql-query -o defaults-file=~/.my.cnf ...
```

## Configuration File

Configuration files are sourced as bash, loaded in order (later overrides earlier):

1. `~/.mysql-queryrc` — Global defaults
2. `./.mysql-queryrc` — Project-local overrides
3. `./.mysql-queryrc.dist` — Fallback if `.mysql-queryrc` missing

Example `~/.mysql-queryrc`:

```bash
# MySQL client options
MYSQL_OPTIONS+=(
    --host=localhost
    --user=myuser
    --database=mydb
)

# Output format (tsv, table, vertical, html, xml)
FORMAT=table

# Suppress query echo
QUIET=1
```

**Project-local configuration**: Commit `.mysql-queryrc.dist` with shared defaults to version control, add `.mysql-queryrc` to `.gitignore` for local customization.

Override the global config file location with the `MYSQL_QUERYRC` environment variable:

```bash
MYSQL_QUERYRC=/path/to/config mysql-query select %a from users
```

Command-line options always override config file settings. Loaded config files are shown on stderr (use `-q` to suppress).

## Shell Aliases

Create aliases in your `~/.bashrc` or `~/.zshrc` to avoid repeating connection options:

```bash
# Basic alias for a specific database
alias mydb='mysql-query -o database=mydb'

# Usage: mydb select %a from users where id=:1

# Alias with full connection details
alias proddb='mysql-query -o host=db.example.com -o user=admin -o database=production'

# Usage: proddb select %count from orders where status=:pending

# Alias using a defaults file
alias q='mysql-query -o defaults-file=~/.my.cnf -o database=mydb'

# Usage: q select %a from users +
```

After adding aliases, reload your shell configuration:

```bash
source ~/.bashrc  # or source ~/.zshrc
```

## Running Tests

```bash
make test
```

Requires [bats](https://github.com/bats-core/bats-core) (Bash Automated Testing System).

## License

MIT
