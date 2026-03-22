# AppSecAI CLI

Command-line tool for AppSecAI vulnerability scanning and remediation.


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

# PRs are created automatically by default after remediation.
# To disable PR creation:
appsecai submit results.sarif --repo owner/repo --branch main --no-auto-create-prs

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

| Flag                      | Description                                                 |
| ------------------------- | ----------------------------------------------------------- |
| `-r, --repo <owner/repo>` | Repository (required)                                       |
| `-b, --branch <branch>`   | Branch to remediate (required)                              |
| `--no-auto-create-prs`    | Prevent automatic PR creation (PRs are created by default)  |
| `-m, --mode <mode>`       | Processing mode (`individual_cc`, `group_cc`, `individual`) |

---

## Usage Examples

### Submit and watch

```bash
# Submit SARIF file
appsecai submit results.sarif --repo myorg/myrepo --branch main

# Watch live progress
appsecai watch <run-id>
```

### Submit without auto-PR creation

```bash
appsecai submit results.sarif --repo myorg/myrepo --branch main --no-auto-create-prs
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


---

## Configuration

Canonical configuration and endpoint routing references:

- [Internal Developer Guide](https://portal.cloud.appsecai.io/docs/cli#install)
- [Environment Endpoints (canonical)](https://portal.cloud.appsecai.io/docs/cli#usage)
- [Testing Guide](https://portal.cloud.appsecai.io/docs/cli#usage)

---

## Troubleshooting

Use canonical troubleshooting guidance:

- [Troubleshooting](https://portal.cloud.appsecai.io/docs/cli#troubleshooting)

---

## Documentation

- [README Routing Matrix](https://portal.cloud.appsecai.io/docs/cli#usage)
- [Quick Start](https://portal.cloud.appsecai.io/docs/cli#install)
- [Internal Developer Guide](https://portal.cloud.appsecai.io/docs/cli#install)
- [Testing Guide](https://portal.cloud.appsecai.io/docs/cli#usage)
- [Automated Testing Details](https://portal.cloud.appsecai.io/docs/cli#usage)
- [Release Process](https://portal.cloud.appsecai.io/docs/cli#usage)
- [Environment Endpoints (canonical)](https://portal.cloud.appsecai.io/docs/cli#usage)
- [Troubleshooting](https://portal.cloud.appsecai.io/docs/cli#troubleshooting)
- [Phase 2 Release Tracker](https://portal.cloud.appsecai.io/docs/cli#usage)

---

## Support

- Support: `https://portal.cloud.appsecai.io/support`
- Support: `https://portal.cloud.appsecai.io/support`

---

## License

MIT
