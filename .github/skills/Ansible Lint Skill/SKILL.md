---
name: Ansible Lint Skill
description: >
  Valide la syntaxe et les bonnes pratiques d'un projet Ansible (ansible-lint + yamllint)
  sur code-vm avant tout commit ou push. Invoquer avec /lint ou avant tout git push
  sur un fichier YAML ou playbook Ansible.
allowed-tools: shell
---
# Ansible Lint Skill

## Objectif

Exécuter `ansible-lint` et `yamllint` sur un projet Ansible depuis code-vm.
Bloque le commit si des erreurs sont détectées.

## Prérequis

- VM `code-vm` accessible via SSH (user `copilot`, clé `~/.ssh/copilot@code-vm`)
- `ansible-lint` et `yamllint` installés sur code-vm

## Procédure

1. Copier le projet sur code-vm
2. Exécuter `yamllint` sur tous les fichiers `.yml`
3. Exécuter `ansible-lint` sur le projet
4. Afficher un rapport clair pass/fail
5. Nettoyer les fichiers temporaires

## Invocation

```bash
bash /home/yves/ops/my_git/copilot-ops/skills/Ansible\ Lint\ Skill/lint.sh <chemin_du_projet>
```

## Règle harness

> Ne jamais `git push` un playbook Ansible ou fichier YAML sans avoir invoqué ce skill au préalable.
> Ne jamais `git push` sans validation humaine.
