# AppSecAI CLI

Command-line tool for AppSecAI that lets you submit SARIF scan results and track automated fix progress directly from your terminal or CI pipeline.

- Submit SARIF files and trigger fix workflows in one command
- Designed for local terminals and headless VM/CI environments


---

## Quick Start

```bash
# Install
curl -fsSL https://raw.githubusercontent.com/AppSecureAI/appsecai-cli/main/install.sh | bash
```


```bash
# Authenticate — paste your AppSecAI token when prompted
appsecai login

# Submit a SARIF file for automated scanning and remediation
appsecai submit results.sarif --repo owner/repo --branch main

# Check fix status (one-time snapshot)
appsecai status <run-id>

# Watch live progress through Find → Triage → Remediation → Push stages
appsecai watch <run-id>
```


---

## Installation

### Recommended: Binary Install

```bash
curl -fsSL https://raw.githubusercontent.com/AppSecureAI/appsecai-cli/main/install.sh | bash
appsecai --version
```


macOS verification (recommended):

```bash
file /usr/local/bin/appsecai
codesign -dv --verbose=4 /usr/local/bin/appsecai
appsecai --version
```

If runtime is blocked on macOS (for example `zsh: killed`):

```bash
sudo xattr -d com.apple.provenance /usr/local/bin/appsecai 2>/dev/null || true
sudo xattr -d com.apple.quarantine /usr/local/bin/appsecai 2>/dev/null || true
sudo codesign -f -s - /usr/local/bin/appsecai
appsecai --version
```

Installer behavior:

- Installs to `/usr/local/bin/appsecai`
- Creates a legacy alias at `/usr/local/bin/appsecai-cli` for backward compatibility only; use `appsecai` in new commands/docs
- May request `sudo` if `/usr/local/bin` is not writable

For full installation options, see the [installation guide](https://portal.cloud.appsecai.io/docs/cli#install).

---

## Authentication

Authenticate with your AppSecAI token. If `-t` is omitted, the token is prompted interactively (input hidden):

```bash
appsecai login
# Paste your CLI token (input hidden), press Enter to continue
```

Provide the token non-interactively:

```bash
appsecai login -t <your-token>
```


Log out and remove stored credentials:

```bash
appsecai logout

# Skip confirmation prompt:
appsecai logout --force
```

---

## Commands

| Command                                              | Description                                                      |
| ---------------------------------------------------- | ---------------------------------------------------------------- |
| `appsecai login [-t <token>] [-u <url>]`             | Authenticate; prompts for token interactively if `-t` is omitted |
| `appsecai submit <file> -r <owner/repo> -b <branch>` | Submit a SARIF file to start scanning and remediation            |
| `appsecai watch <run-id>`                            | Watch fix progress live (Find → Triage → Remediation → Push)     |
| `appsecai status <run-id> [-j]`                      | Check fix status snapshot; `-j/--json` outputs JSON              |
| `appsecai logout [-f]`                               | Remove stored credentials; `-f/--force` skips confirmation       |
| `appsecai version`                                   | Print CLI version                                                |
| `appsecai --help`                                    | Show command usage                                               |

Key `submit` flags:

| Flag                      | Description                                                |
| ------------------------- | ---------------------------------------------------------- |
| `-r, --repo <owner/repo>` | Repository (required)                                      |
| `-b, --branch <branch>`   | Branch to remediate (required)                             |
| `--no-auto-create-prs`    | Prevent automatic PR creation (PRs are created by default) |


---

## Usage Examples

### Submit and watch

```bash
# Submit SARIF file
appsecai submit results.sarif --repo myorg/myrepo --branch main

# Watch live progress
appsecai watch <run-id>
```


### Check status in JSON format

```bash
appsecai status <run-id> --json
```

### Full flow

```bash
appsecai login
appsecai submit results.sarif --repo myorg/myrepo --branch main
appsecai watch <run-id>
appsecai status <run-id>
```


For more usage examples, see the [usage guide](https://portal.cloud.appsecai.io/docs/cli#usage).

---

## Configuration


---

## Troubleshooting

For troubleshooting help, see the [troubleshooting guide](https://portal.cloud.appsecai.io/docs/cli#troubleshooting).


---

## Documentation


---

## Support

- Support: `https://portal.cloud.appsecai.io/support`

---

## License

MIT
