# Copilot Instructions — copilot-ops

## Build, test, and lint commands

This repo is a Copilot CLI harness, not an application codebase.

```bash
# Full harness eval suite
bash .github/evals/run-evals.sh

# Single targeted guardrail test
bash .github/evals/adversarial/test-paths.sh

# Ansible/YAML lint before push
bash .github/skills/Ansible\ Lint\ Skill/lint.sh /path/to/ansible_project

# Run a playbook in the ephemeral code-vm sandbox
bash .github/skills/sandbox--ansible/sandbox--ansible.sh /path/to/ansible_project [playbook.yml]

# Weekly summary from history files
bash .github/skills/observability/weekly-report.sh .github/history
```

## High-level architecture

The repo is a 3-layer harness:

1. **Policy layer** (`.github/instructions/`) defines scope, access, allowed paths, RTK usage, sources, and Green AI constraints.
2. **Execution layer** (`.github/skills/`, `.github/scripts/`) provides runnable guardrails and automation: Ansible linting, sandbox playbook runs, path checks, observability reporting, and Headroom updates.
3. **Evidence layer** (`.github/history/`, `.github/knowledge/`, `.github/evals/`) stores the daily execution trace, sandbox artifacts, and eval cases/results.

The expected flow is: **read policy -> execute via skills/scripts -> record evidence**.

## Key conventions

### Command and runtime conventions

- Use `rtk` wrappers when an equivalent exists (`rtk git`, `rtk gh`, `rtk find`, `rtk grep`, `rtk diff`, `rtk curl`, etc.).
- Prefer `gh` for GitHub operations and Linux/WSL paths in commands and examples.
- Exceptions to `rtk`: interactive commands that need stdin, or raw parsers like `jq`/`awk`; otherwise prefer `rtk proxy <cmd>` when you need unfiltered output.

### Validation and safety

- Before any `git push` that touches YAML or Ansible, run the Ansible lint skill and the sandbox flow:
  - `bash .github/skills/Ansible\ Lint\ Skill/lint.sh <path>`
  - `bash .github/skills/sandbox--ansible/sandbox--ansible.sh <path> [playbook.yml]`
- Use `bash .github/skills/guardrails/check-paths.sh <path>` before writing outside familiar areas; the authoritative whitelist lives in `.github/instructions/access.instructions.md`.
- Never auto-merge. Any destructive or irreversible action needs explicit human approval.
- Follow the autonomy matrix in `.github/instructions/scope.instructions.md`: playbooks and YAML are co-pilot, actions inside the sandbox container are autonomous, and VM/SSH/firewall/sudoers changes are HITL.

### Headroom and reporting

- If `headroom` is available, start the local proxy with `headroom proxy --port 8787`.
- Local clients should use:
  - `OPENAI_BASE_URL=http://localhost:8787/v1`
  - `ANTHROPIC_BASE_URL=http://localhost:8787`
- Keep daily reporting consolidated in `.github/history/YYYY-MM-DD.md` using the `HISTORY_AUTO` block and log updates to `.github/knowledge/headroom_updates.log`.
- The updater parses proxy stats with `jq` and refreshes the consolidated history file on a 30-minute cadence.

### Evals and repository workflow

- Run `bash .github/evals/run-evals.sh` before changing this instruction file, a skill, or another instruction file.
- `nominal/` should pass, `edge/` may expose known sandbox limits, and `adversarial/` must be blocked by guardrails.

## Skills referenced here

| Skill | Primary use | Typical invocation |
|---|---|---|
| `Ansible Lint Skill` | Validate YAML + Ansible before commit/push | `bash .github/skills/Ansible\ Lint\ Skill/lint.sh <path>` |
| `sandbox--ansible` | Test playbooks safely in an ephemeral container | `bash .github/skills/sandbox--ansible/sandbox--ansible.sh <path> [playbook.yml]` |
| `guardrails` | Enforce allowed path boundaries | `bash .github/skills/guardrails/check-paths.sh <path>` |
| `observability` | Weekly report from history metrics | `bash .github/skills/observability/weekly-report.sh [.github/history]` |
| `adhd` | Divergent ideation for open-ended design/debug | `/adhd` |
