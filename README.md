# AppSecAI CLI

Command-line tool for AppSecAI that lets you submit SARIF, JSON, CSV, TSV, or XML vulnerability results and track automated fix progress directly from your terminal or CI pipeline.

- Submit SARIF, JSON, CSV, TSV, or XML files and trigger fix workflows in one command
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

# Submit a SARIF, JSON, CSV, TSV, or XML file for automated scanning and remediation
appsecai submit results.sarif --repo owner/repo --branch main

# Submit multiple scanner outputs as one multi-SAST run
appsecai submit --files "semgrep.sarif,codeql.sarif" --repo owner/repo --branch main

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

| Command                                                                  | Description                                                                |
| ------------------------------------------------------------------------ | -------------------------------------------------------------------------- |
| `appsecai login [-t <token>] [-u <url>]`                                 | Authenticate; prompts for token interactively if `-t` is omitted           |
| `appsecai submit <file> -r <owner/repo> -b <branch>`                     | Submit SARIF, JSON, CSV, TSV, or XML to start scanning and remediation     |
| `appsecai submit --files <paths> -r <owner/repo> -b <branch>`            | Submit multiple files as one multi-SAST run                                |
| `appsecai watch <run-id> [--org-id <org-id>]`                            | Watch fix progress live; CI flags can fail on timeout and write summaries  |
| `appsecai status <run-id> [--org-id <org-id>] [-j]`                      | Check fix status snapshot; `-j/--json` outputs JSON                        |
| `appsecai results <run-id> [--show] [--download] [--include-fixed-code]` | Preview run results, show grouped inline output, or download full artifact |
| `appsecai logout [-f]`                                                   | Remove stored credentials; `-f/--force` skips confirmation                 |
| `appsecai doctor [--repo <owner/repo>] [--file <path>] [-j]`             | Diagnose auth, endpoint, repository, backend, and file setup               |
| `appsecai version`                                                       | Print CLI version                                                          |
| `appsecai --help`                                                        | Show command usage                                                         |

Key `submit` flags:

| Flag                          | Description                                                                                                                                      |
| ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| `-r, --repo <owner/repo>`     | Repository (required)                                                                                                                            |
| `-b, --branch <branch>`       | Branch to remediate (required)                                                                                                                   |
| `--files <paths>`             | Comma- or newline-separated vulnerability result files; supports simple `*` and `**` globs                                                       |
| `--auto-create-prs`           | Enable automatic PR creation (PRs are not created by default)                                                                                    |
| `-m, --mode <mode>`           | Processing mode (`individual_cc` default; `group_cc` groups related vulnerabilities; `individual` keeps one PR per finding without code context) |
| `--pr-audience <values>`      | Target generated PR content for `security`, `engineering`, or both audiences                                                                     |
| `--allow-missing-repo-access` | Start the run even if the AppSecAI GitHub App cannot yet push to the target repo (default: off; without it, submit fails fast). See below.       |

Use `--mode group_cc` when you want fewer, consolidated remediation PRs.

CSV, TSV, and XML content is accepted by the CLI and validated by the backend. Use `--skip-content-validation` when you want JSON/SARIF content checks delegated to the backend as well.

### Missing repo push access (fail fast + override)

Before a run starts, the platform verifies that the AppSecAI GitHub App can push
to the target repository. If it cannot, `submit` **fails fast** with a non-zero
exit and an actionable message (which repo, why, and how to fix it) instead of
starting a run that could do hours of work and then fail at PR-push time.

Use `--allow-missing-repo-access` for the licensed-org case: your organization is
licensed and the App is installed, but the target repository simply has not been
added to the App yet. The run starts immediately, and the pull requests with the
fixes are pushed once the repository is added to the AppSecAI GitHub App. When the
flag is used, the CLI prints a notice that fixes will not be delivered until repo
access is granted.

```bash
# Start now even though the repo isn't added to the App yet
appsecai submit results.sarif --repo myorg/myrepo --branch main --allow-missing-repo-access
```

Key `watch` flags:

| Flag                    | Description                                                     |
| ----------------------- | --------------------------------------------------------------- |
| `--fail-on-timeout`     | Exit non-zero if watch reaches `--timeout`                      |
| `--finalize`            | Compute the final server summary before writing terminal output |
| `--compute-summary`     | Alias for `--finalize`                                          |
| `--summary-json <path>` | Write terminal run status and summary JSON                      |
| `--summary-md <path>`   | Write terminal run status and summary markdown                  |
| `-j, --json`            | Print terminal watch result as JSON                             |

Key `results` flags:

| Flag                   | Description                                                          |
| ---------------------- | -------------------------------------------------------------------- |
| `--show`               | Show grouped PR/issue results inline in the terminal (no file write) |
| `--download`           | Download full JSON artifact to `appsecai-results-<run-id>.json`      |
| `--include-fixed-code` | Include fixed-code payload in `--show` or `--download` output        |

---

## Usage Examples

### Submit and watch

```bash
# Submit SARIF, JSON, CSV, TSV, or XML file
appsecai submit results.sarif --repo myorg/myrepo --branch main

# Submit multiple SAST outputs in one run
appsecai submit --files "semgrep.sarif,codeql.sarif,bandit.json" --repo myorg/myrepo --branch main

# Newline-separated and glob inputs are also supported
appsecai submit --files $'semgrep.sarif\ncodeql.sarif' --repo myorg/myrepo --branch main
appsecai submit --files "reports/**/*.sarif" --repo myorg/myrepo --branch main

# Watch live progress
appsecai watch <run-id>

# CI-safe watch: fail on timeout, compute summary, and write artifacts
appsecai watch <run-id> --fail-on-timeout --finalize --summary-json summary.json --summary-md summary.md --json

# Watch or fetch status through org-scoped endpoints when available
appsecai watch <run-id> --org-id <org-id>
appsecai status <run-id> --org-id <org-id>
```


### Check status in JSON format

```bash
appsecai status <run-id> --json
```

### Preview and download results

```bash
# Preview mode: summary-oriented terminal output
appsecai results <run-id>

# Show mode: grouped terminal output (no artifact file write)
appsecai results <run-id> --show

# Download mode: writes full JSON artifact to disk
appsecai results <run-id> --download

# Show grouped output with per-file fixed code blocks
appsecai results <run-id> --show --include-fixed-code

# Download complete payload including fixed code
appsecai results <run-id> --download --include-fixed-code
```

Typical post-completion evaluation sequence:

1. `appsecai results <run-id>` for fast preview.
2. `appsecai results <run-id> --show` for grouped terminal deep-dive.
3. `appsecai results <run-id> --download` for full artifact retrieval.

#### Interpreting consistency signals

The `results` command surfaces coverage differences as `[SUMMARY_COUNT_MISMATCH]` warnings. The
message text distinguishes two lifecycle phases:

- **Advisory** (non-terminal runs such as `in_progress`): row coverage can be partial while the run
  is still executing. Re-check after the run completes.
- **Actionable** (terminal runs: `completed`, `failed`, `cancelled`): a difference on a finished run
  warrants investigation. Use `--download` to inspect the raw artifact.

Counter semantics — these counters represent **different dimensions** and may not be equal even for
correct data:

| Counter A                                                     | Counter B                          | Expected relationship  |
| ------------------------------------------------------------- | ---------------------------------- | ---------------------- |
| `covered_vulnerability_count + uncovered_vulnerability_count` | `summary.total_vulnerabilities`    | MUST equal             |
| `sum(uncovered_reasons)`                                      | `uncovered_vulnerability_count`    | MUST equal             |
| Distinct PR URL count                                         | Vulnerability-indexed PR row count | Intentionally distinct |

When `uncovered_reasons` is present in the payload, `--show` renders a bucket breakdown using
canonical labels (`Deduplicated findings`, `Filtered by policy`, `No remediation artifact produced`)
with a sanitized fallback for unrecognised keys.

Grouped PR rows include a grouped-fix line when the server provides grouping metadata, for example
`Grouped fix: PR #3422 fixes 2 vulnerabilities`.

#### Fixed-code provenance labels

When using `--show --include-fixed-code`, each fixed-code block displays a `Provenance:` line:

| Server value             | User-facing label      |
| ------------------------ | ---------------------- |
| `final_artifact`         | Final artifact         |
| `grouped_final_artifact` | Grouped final artifact |
| `remediate_fallback`     | Remediation fallback   |
| `unavailable` or unknown | Unavailable            |

### Full flow

#### Interactive path (`submit -> watch -> results`)

```bash
appsecai login
appsecai submit results.sarif --repo myorg/myrepo --branch main
appsecai watch <run-id>
appsecai results <run-id>
```

#### Snapshot path (`submit -> status -> results`)

```bash
appsecai login
appsecai submit results.sarif --repo myorg/myrepo --branch main
appsecai status <run-id>
appsecai results <run-id>
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

- Issues: Use the repository issue tracker in your current repo host.

---

## License

MIT
