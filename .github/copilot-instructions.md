---
date: 2026-06-25
tags: [instructions, copilot]
status: active
project: copilot-ops
type: instructions
---

# Copilot Instructions — copilot-ops

## Build, test, and lint commands

This repo is a Copilot CLI harness, not an application codebase.

```bash
# Full harness eval suite
bash .github/evals/run-evals.sh

# Single targeted guardrail test (one-test run)
bash .github/evals/adversarial/test-paths.sh

# Ansible/YAML lint before push
bash .github/skills/Ansible\ Lint\ Skill/lint.sh /path/to/ansible_project

# Run a playbook in the ephemeral code-vm sandbox
bash .github/skills/sandbox--ansible/sandbox--ansible.sh /path/to/ansible_project [playbook.yml]

# Weekly summary from history files
bash .github/skills/observability/weekly-report.sh .github/history

# Validate frontmatter on all notes (or one file path)
bash .github/scripts/validate-frontmatter.sh [path]

# Validate only this instruction file
bash .github/scripts/validate-frontmatter.sh .github/copilot-instructions.md

# Mise à jour manuelle immédiate (history + knowledge + plan.md + commit+push)
bash .github/skills/headroom_updater.sh

# Hook de fin de session (frontmatter check + update final)
bash .github/scripts/end-session.sh

# Installer le timer auto (à faire une seule fois par machine WSL)
bash .github/scripts/install-updater.sh
```

## High-level architecture

The repo is a 4-part harness:

1. **Bootstrap layer** (`bootstrap-copilot.sh`) prints the instructions checksum/content first, enforces `--ack`, and auto-starts Headroom on `localhost:8787` when available.
2. **Policy layer** (`.github/instructions/`) defines autonomy level, allowed paths, mandatory RTK wrappers, and source-of-truth policy.
3. **Execution layer** (`.github/skills/`, `.github/scripts/`, `.github/systemd/`) provides runnable guardrails and automation: Ansible linting, sandbox playbook runs, path checks, periodic Headroom updater, end-session hook, and user timer install.
4. **Evidence layer** (`.github/history/`, `.github/knowledge/`, `.github/evals/`) stores consolidated daily reports, updater logs, and eval scenarios/results.

The expected flow is: **read policy -> execute via skills/scripts -> record evidence**.

## Key conventions

### Command and runtime conventions

- Use `rtk` wrappers when an equivalent exists (`rtk git`, `rtk gh`, `rtk find`, `rtk grep`, `rtk diff`, `rtk curl`, etc.).
- Prefer `gh` for GitHub operations and Linux/WSL paths in commands and examples.
- Exceptions to `rtk`: interactive commands that need stdin, or raw parsers like `jq`/`awk`; otherwise prefer `rtk proxy <cmd>` when you need unfiltered output.
- Start sessions through `./bootstrap-copilot.sh --ack` so `.github/copilot-instructions.md` is always read first.
- Headroom now starts by default in bootstrap when available; use `--no-headroom` to opt out for a session.

### Validation and safety

- Before any `git push` that touches YAML or Ansible, run the Ansible lint skill and the sandbox flow:
  - `bash .github/skills/Ansible\ Lint\ Skill/lint.sh <path>`
  - `bash .github/skills/sandbox--ansible/sandbox--ansible.sh <path> [playbook.yml]`
- Use `bash .github/skills/guardrails/check-paths.sh <path>` before writing outside familiar areas.
- Keep guardrail whitelist in `check-paths.sh` aligned with `.github/instructions/access.instructions.md` (both are used as control points).
- Never auto-merge. Any destructive or irreversible action needs explicit human approval.
- Follow the autonomy matrix in `.github/instructions/scope.instructions.md`: playbooks and YAML are co-pilot, actions inside the sandbox container are autonomous, and VM/SSH/firewall/sudoers changes are HITL.

### Headroom and reporting

- If `headroom` is available, bootstrap starts `headroom proxy --port 8787` automatically (unless `--no-headroom` is passed).
- Local clients should use:
  - `OPENAI_BASE_URL=http://localhost:8787/v1`
  - `ANTHROPIC_BASE_URL=http://localhost:8787`
- Keep daily reporting consolidated in `.github/history/YYYY-MM-DD.md` using the `HISTORY_AUTO` block and log updates to `.github/knowledge/headroom_updates.log`.
- The updater parses proxy stats with `jq` and refreshes the consolidated history file on a 30-minute cadence: `bash .github/skills/headroom_updater.sh`.
- Sync `.github/plan.md` to session state: `bash .github/scripts/sync-plan.sh`.
- `headroom_updater.sh`, `end-session.sh`, and `sync-plan.sh` assume the repository path `/home/yves/ops/my_git/copilot-ops`.

### Vault memory conventions (Obsidian-first)

- Follow the frontmatter contract in `[[.github/knowledge/vault-schema]]`.
- Keep canonical indexes in `[[.github/knowledge/vault-index]]` and `_manifest.json`.
- Use wiki-links (`[[...]]`) and maintain backlinks to at least one hub note per active note.
- Every markdown file requires these frontmatter fields: `date`, `tags`, `status`, `project`, `type`.
  - `status` ∈ `active | draft | archived`
  - `type` ∈ `instructions | connaissance | ressource | journal | rapport | runbook`
- Validate frontmatter: `bash .github/scripts/validate-frontmatter.sh [path]`

### Evals and repository workflow

- Run `bash .github/evals/run-evals.sh` before changing this instruction file, a skill, or another instruction file.
- `adversarial/` must be blocked by guardrails; `nominal/` and `edge/` are sandbox-dependent and are skipped when `code-vm` is unreachable.

## Skills referenced here

| Skill | Primary use | Typical invocation |
|---|---|---|
| `Ansible Lint Skill` | Validate YAML + Ansible before commit/push | `bash .github/skills/Ansible\ Lint\ Skill/lint.sh <path>` |
| `sandbox--ansible` | Test playbooks safely in an ephemeral container | `bash .github/skills/sandbox--ansible/sandbox--ansible.sh <path> [playbook.yml]` |
| `guardrails` | Enforce allowed path boundaries | `bash .github/skills/guardrails/check-paths.sh <path>` |
| `observability` | Weekly report from history metrics | `bash .github/skills/observability/weekly-report.sh [.github/history]` |
| `adhd` | Divergent ideation for open-ended design/debug | `/adhd` |

## Integrated references

- `.github/evals/README.md` for eval workflow and pre-change gate.
- `.github/instructions/scope.instructions.md` for autonomy/HITL boundaries.
- `.github/instructions/access.instructions.md` for writable/forbidden path policy.
- `.github/instructions/rtk.instructions.md` for mandatory command wrapping and exceptions.
- `.github/instructions/green.instructions.md` for Headroom routing and consolidated history reporting.
