# 🐬 mq

A Bash-based MySQL/MariaDB client wrapper with argument expansion and SQL shorthand helpers.

## ✨ Features

- 🚀 Query database directly from Bash/Zsh: `mq select %all from users > users.tsv`
- ⚡ [SQL shorthand helpers](#-argument-shortcuts) for common patterns (strings, JSON paths, operators)
- 🎨 Smart [output format](#-options-reference): `table` for terminal, `tsv` for pipes (override with `-f`)
- 📊 [Trailing `+`](#-argument-shortcuts) for vertical output (like MySQL/MariaDB's `\G`)
- 🔍 Automatic query echo to stderr for debugging (suppress with `-q`)
- 🌈 [Syntax highlighting](#-syntax-highlighting-optional) with grcat (auto-detected)
- 🔤 [Bash completion](#-bash-completion-optional) for options, SQL keywords, and mq tokens
- ⚙️ Global and project-local [configuration files](#️-configuration-file-optional)

## 📦 Installation

### Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/bdelespierre/mq/master/install.sh | bash
```

<details>
<summary>Manual Install</summary>

Clone the repository:
```bash
git clone https://github.com/bdelespierre/mq.git
cd mq
```

Install using make (installs to `~/.local`):
```bash
make install
```

Or install system-wide (requires sudo):
```bash
sudo make install-system
```

Alternatively, add the `bin` directory to your PATH:
```bash
export PATH="$PATH:$(pwd)/bin"
```

</details>

<details>
<summary>Uninstallation</summary>

```bash
make uninstall
```

Or if installed system-wide:
```bash
sudo make uninstall-system
```

</details>

## 🔧 Usage

```bash
# Basic query with string shorthand (:value becomes 'value')
mq -o database=mydb select '*' from users where name=:john

# Count with comparison operator
mq -o database=mydb select %count from users where age %gt 18

# Select all columns with alias
mq -o database=mydb select %all from products where price %lte 99.99

# JSON path extraction
mq -o database=mydb select %json settings.ui.dark_mode from users where id=123

# Vertical output with trailing +
mq -o database=mydb select %a from users where id=:1 +

# Use with pager
PAGER=less mq -o database=mydb select %a from large_table
```

## 📋 Options Reference

| Option | Description |
|--------|-------------|
| `-h, --help` | Show help message |
| `-v, --version` | Show version and exit |
| `-o, --option NAME[=VALUE]` | Set MySQL/MariaDB client option (see `mysql --help`) |
| `-f, --format NAME` | Output format: `table`, `tsv`, `vertical`, `html`, `xml`. Default: `table` (TTY) or `tsv` (pipe) |
| `-q, --quiet` | Suppress query echo to stderr |
| `-n, --dry-run` | Show query without executing |
| `-i, --input FILE` | Read query from file (use `-` for stdin) |
| `--color[=WHEN]` | Colorize output: `auto` (default), `always`, `never`. Requires grcat |

## ⚡ Argument Shortcuts

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

## 🐬 MySQL/MariaDB Options

Pass MySQL/MariaDB client options with `-o`:

```bash
# Connect to specific database
mq -o database=mydb ...

# Connect to remote host
mq -o host=db.example.com -o user=admin -o password=secret ...

# Use specific port
mq -o port=3307 ...

# Use defaults file
mq -o defaults-file=~/.my.cnf ...
```

## ⚙️ Configuration File (optional)

Configuration files are sourced as bash, loaded in order (later overrides earlier):

1. `~/.mqrc` — Global defaults
2. `./.mqrc` — Project-local overrides
3. `./.mqrc.dist` — Fallback if `.mqrc` missing

Example `~/.mqrc`:

```bash
# MySQL/MariaDB client options
MYSQL_OPTIONS+=(
    --host=localhost
    --user=myuser
    --database=mydb
)

# Output format: table, tsv, vertical, html, xml
# Default is table (TTY) or tsv (pipe); override here:
FORMAT=table

# Suppress query echo
QUIET=1
```

See [.mqrc.example](.mqrc.example) for a complete annotated template.

**Project-local configuration**: Commit `.mqrc.dist` with shared defaults to version control, add `.mqrc` to `.gitignore` for local customization.

Override the global config file location with the `MQRC` environment variable:

```bash
MQRC=/path/to/config mq select %a from users
```

> **Note:** Command-line options always override config file settings.

## 🔗 Shell Aliases (optional)

Create aliases in your `~/.bashrc` or `~/.zshrc` to avoid repeating connection options:

```bash
# Basic alias for a specific database
alias mydb='mq -o database=mydb'

# Usage: mydb select %a from users where id=:1

# Alias with full connection details
alias proddb='mq -o host=db.example.com -o user=admin -o database=production'

# Usage: proddb select %count from orders where status=:pending

# Alias using a defaults file
alias q='mq -o defaults-file=~/.my.cnf -o database=mydb'

# Usage: q select %a from users +
```

After adding aliases, reload your shell configuration:

```bash
source ~/.bashrc  # or source ~/.zshrc
```

## 🔤 Bash Completion (optional)

Bash completion is installed automatically with `make install`. It provides completion for options, formats, SQL keywords, and mq shorthand tokens.

After installation, reload your shell or source the completion manually:

```bash
# If installed locally
source ~/.local/share/bash-completion/completions/mq

# If installed system-wide
source /usr/local/share/bash-completion/completions/mq

# Or source directly from repo
source share/bash-completion/completions/mq
```

Completions available:
- **Options**: `-f`, `--format`, `-o`, `--option`, `-q`, `--quiet`, etc.
- **Formats**: `table`, `vertical`, `html`, `xml`, `tsv`
- **MySQL options**: `database=`, `host=`, `port=`, `user=`, etc.
- **SQL keywords**: `select`, `from`, `where`, `order`, `join`, etc.
- **mq tokens**: `%all`, `%count`, `%rand`, `%eq`, `%gt`, `%in`, `%json`, etc.

## 🌈 Syntax Highlighting (optional)

When [grc](https://github.com/garabik/grc) is installed, mq automatically colorizes output. The grc config is installed alongside mq at `$PREFIX/share/grc/conf.mq` (e.g., `~/.local/share/grc/conf.mq` for local installs).

Colors applied:
- **Green**: default text
- **Red**: table borders
- **Yellow**: numbers, schema names
- **Cyan**: dates, times, IP addresses
- **Magenta**: email addresses
- **White**: vertical format delimiters and column names

To disable colorization:
```bash
mq --color=never select %all from users
```

## 🧪 Running Tests

```bash
make test
```

Requires [bats](https://github.com/bats-core/bats-core) (Bash Automated Testing System).

## 📄 License

MIT
