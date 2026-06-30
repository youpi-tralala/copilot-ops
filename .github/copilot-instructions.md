---
date: 2026-06-25
tags: [instructions, copilot]
status: active
project: copilot-ops
type: instructions
---

# Instructions Copilot — copilot-ops

## Démarrage rapide

```bash
# Démarrer une session (lit les instructions, démarre Headroom si dispo)
./bootstrap-copilot.sh --ack

# Valider avant tout push
bash .github/evals/run-evals.sh          # suite complète d'evals
bash .github/scripts/validate-frontmatter.sh [chemin]  # frontmatter markdown
```

## Commandes de build, test, et lint

Ce repo est un harness Copilot CLI, pas une application.

```bash
# Suite d'evals complète du harness
bash .github/evals/run-evals.sh

# Test guardrail ciblé (chemins non autorisés)
bash .github/evals/adversarial/test-paths.sh

# Lint Ansible/YAML avant push
bash .github/skills/Ansible\ Lint\ Skill/lint.sh /chemin/ansible

# Exécuter un playbook dans le sandbox éphémère (code-vm)
bash .github/skills/sandbox--ansible/sandbox--ansible.sh /chemin/ansible [playbook.yml]

# Rapport hebdomadaire depuis les fichiers d'historique
bash .github/skills/observability/weekly-report.sh .github/history

# Valider frontmatter sur tous les notes (ou un seul fichier)
bash .github/scripts/validate-frontmatter.sh [chemin]

# Mise à jour manuelle immédiate (historique + connaissance + plan.md)
bash .github/scripts/headroom_updater.sh

# Hook de fin de session (vérification frontmatter + mise à jour finale)
bash .github/scripts/end-session.sh

# Installer le timer auto (une seule fois par machine WSL)
bash .github/scripts/install-updater.sh
```

## Architecture générale

Le repo est un harness à 4 niveaux :

1. **Couche bootstrap** (`bootstrap-copilot.sh`) : lit les instructions en premier (avec checksum SHA256), enforce `--ack`, démarre automatiquement Headroom sur `localhost:8787` si disponible.
2. **Couche politique** (`.github/instructions/`) : définit les niveaux d'autonomie, chemins autorisés, wrappers RTK obligatoires, source-of-truth policy.
3. **Couche exécution** (`.github/skills/`, `.github/scripts/`, `.github/systemd/`) : fournit guardrails et automatisations : lint Ansible, exécution playbook en sandbox, vérification chemins, updater périodique Headroom, hook fin de session, install timer utilisateur.
4. **Couche évidence** (`.github/history/`, `.github/knowledge/`, `.github/evals/`) : stocke rapports consolidés quotidiens, logs updater, scénarios et résultats d'evals.

**Flux attendu** : lire policy → exécuter via skills/scripts → enregistrer évidence.

## Conventions clés

### Commandes et conventions runtime

- Utiliser `rtk` quand un équivalent existe (`rtk git`, `rtk gh`, `rtk find`, `rtk grep`, `rtk diff`, `rtk curl`, etc.).
- Préférer `gh` pour GitHub et chemins Linux/WSL dans les commandes et exemples.
- Exceptions à `rtk` : commandes interactives nécessitant stdin, ou parsers bruts (jq/awk) ; sinon préférer `rtk proxy <cmd>` si sortie brute nécessaire.
- Démarrer sessions via `./bootstrap-copilot.sh --ack` pour lire les instructions d'abord.
- Headroom démarre par défaut au bootstrap si disponible ; utiliser `--no-headroom` pour opt-out.

### Validation et sécurité

- Avant tout `git push` touchant YAML/Ansible, exécuter :
  - `bash .github/skills/Ansible\ Lint\ Skill/lint.sh <chemin>`
  - `bash .github/skills/sandbox--ansible/sandbox--ansible.sh <chemin> [playbook.yml]`
- Utiliser `bash .github/skills/guardrails/check-paths.sh <chemin>` avant écrire hors zones connues.
- Maintenir whitelist guardrails dans `check-paths.sh` alignée avec `.github/instructions/access.instructions.md`.
- Jamais d'auto-merge. Toute action destructive/irréversible requiert approbation explicite.
- Suivre matrice autonomie dans `.github/instructions/scope.instructions.md` : playbooks/YAML = co-pilote, actions sandbox = autonome, changements VM/SSH/firewall = HITL.

### Headroom et rapports

- Si `headroom` disponible, bootstrap démarre `headroom proxy --port 8787` automatiquement (sauf `--no-headroom`).
- Clients locaux utilisent :
  - `OPENAI_BASE_URL=http://localhost:8787/v1`
  - `ANTHROPIC_BASE_URL=http://localhost:8787`
- Rapports quotidiens consolidés dans `.github/history/YYYY-MM-DD.md` via bloc `HISTORY_AUTO`, logs dans `.github/knowledge/headroom_updates.log`.
- Updater parse stats proxy avec `jq`, rafraîchit historique consolidé toutes les heures : `bash .github/scripts/headroom_updater.sh`.
- Syncer `.github/plan.md` vers session state : `bash .github/scripts/sync-plan.sh`.
- Scripts supposent chemin repo `/home/yves/ops/my_git/copilot-ops`.

### Conventions vault mémoire (Obsidian-first)

- Suivre contrat frontmatter dans `[[.github/knowledge/vault-schema]]`.
- Indexes canoniques dans `[[.github/knowledge/vault-index]]` et `_manifest.json`.
- Utiliser wiki-links (`[[...]]`) et maintenir backlinks vers au moins un hub par note active.
- Chaque fichier markdown requiert frontmatter : `date`, `tags`, `status`, `project`, `type`.
  - `status` ∈ `active | draft | archived`
  - `type` ∈ `instructions | connaissance | ressource | journal | rapport | runbook`
- Valider : `bash .github/scripts/validate-frontmatter.sh [chemin]`

### Evals et workflow repo

- Lancer `bash .github/evals/run-evals.sh` avant changer ce fichier, un skill, ou une instruction.
- `adversarial/` doit être bloqué par guardrails ; `nominal/` et `edge/` sandbox-dépendants, skippés si `code-vm` inaccessible.

## Skills référencés

| Skill | Usage primaire | Invocation typique |
|---|---|---|
| `Ansible Lint Skill` | Valider YAML + Ansible avant commit/push | `bash .github/skills/Ansible\ Lint\ Skill/lint.sh <chemin>` |
| `sandbox--ansible` | Tester playbooks en container éphémère | `bash .github/skills/sandbox--ansible/sandbox--ansible.sh <chemin> [playbook.yml]` |
| `guardrails` | Enforcer limites chemins autorisés | `bash .github/skills/guardrails/check-paths.sh <chemin>` |
| `observability` | Rapport hebdo depuis historique | `bash .github/skills/observability/weekly-report.sh [.github/history]` |
| `adhd` | Idéation divergente pour design/debug open-ended | `/adhd` |

## Références intégrées

- `.github/evals/README.md` — workflow evals et pre-change gate.
- `.github/instructions/scope.instructions.md` — limites autonomie/HITL.
- `.github/instructions/access.instructions.md` — policy chemins autorisés/interdits.
- `.github/instructions/rtk.instructions.md` — wrappers commande obligatoires et exceptions.
- `.github/instructions/green.instructions.md` — routage Headroom et rapports historique consolidés.
- `.github/instructions/sources.instructions.md` — sources de vérité prioritaires (communauté, éditeurs officiels, local).

## Session et planning

**Workflow** :
1. Lancer session : `./bootstrap-copilot.sh --ack` → lit instructions + démarre Headroom
2. Consulter `.github/plan.md` → tâches à faire
3. Exécuter via skills/scripts → Headroom consolide rapports dans `.github/history/YYYY-MM-DD.md`
4. Fin de session : `bash .github/scripts/end-session.sh` → valide frontmatter + snapshot final

**Session state** : `.github/plan.md` est le source-of-truth pour le statut tâches. Synchroniser via `bash .github/scripts/sync-plan.sh`.
