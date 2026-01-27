# mysql-query.bash

A Bash-based MySQL client wrapper with argument expansion and SQL shorthand helpers.

## Features

- SQL shorthand helpers for common patterns (strings, JSON paths, operators)
- Multiple output formats: TSV, table, vertical, HTML, XML
- Trailing `+` for vertical output (like MySQL's `\G`)
- Automatic query echo to stderr for debugging
- Pager support via `$PAGER` environment variable

## Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd mysql-query.bash
   ```

2. Install using make (installs to `/usr/local`):
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

3. Ensure MySQL client is installed:
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
mysql-query -o database=mydb select %a from products where price %lte :99.99

# JSON path extraction
mysql-query -o database=mydb select %json data.user.email from users

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
| `-o, --option NAME=[VALUE]` | Set MySQL client option (see `mysql --help`) |
| `-f, --format NAME` | Output format: `tsv` (default), `table`, `vertical`, `html`, `xml` |
| `-q, --quiet` | Suppress query echo to stderr |
| `-n, --dry-run` | Show query without executing |
| `-i, --input FILE` | Read query from file (use `-` for stdin) |

## Argument Shortcuts

### String Values

| Shorthand | Expansion | Example |
|-----------|-----------|---------|
| `:value` | `'value'` | `where name=:john` → `where name='john'` |
| `%s value`, `%string value` | `'value'` | `%string john` → `'john'` |

### SQL Aliases

| Shorthand | Expansion |
|-----------|-----------|
| `%a`, `%all` | `*` |
| `%c`, `%count` | `count(*)` |
| `%r`, `%rand` | `rand()` |
| `%now` | `now()` |

### Comparison Operators

| Shorthand | Expansion |
|-----------|-----------|
| `%eq` | `=` |
| `%ne` | `<>` |
| `%gt` | `>` |
| `%gte` | `>=` |
| `%lt` | `<` |
| `%lte` | `<=` |
| `%like` | `LIKE` |
| `%null` | `IS NULL` |
| `%notnull` | `IS NOT NULL` |

### IN Clause

| Shorthand | Expansion |
|-----------|-----------|
| `%in :a :b :c` | `IN ('a', 'b', 'c')` |

Example: `where status %in :active :pending` → `where status IN ('active', 'pending')`

### Limit Clause

| Shorthand | Expansion |
|-----------|-----------|
| `%l N`, `%limit N` | `LIMIT N` |

Example: `select %a from users %limit 10` → `select * from users LIMIT 10`

### JSON Path

| Shorthand | Expansion |
|-----------|-----------|
| `%j path`, `%json path` | `json_unquote(json_extract(...))` |

Example: `%json data.user.name` → `json_unquote(json_extract(data, '$.user.name'))`

### Special

| Shorthand | Description |
|-----------|-------------|
| `+` (trailing) | Switch to vertical output format |

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

Default options can be set in `~/.mysql-queryrc`:

```bash
# MySQL connection options (same as command line)
options=--database=mydb --host=localhost --user=myuser

# Output format (tsv, table, vertical, html, xml)
format=table

# Suppress query echo
quiet=true
```

Override the config file location with the `MYSQL_QUERYRC` environment variable:

```bash
MYSQL_QUERYRC=/path/to/config mysql-query select %a from users
```

Command-line options always override config file settings.

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
