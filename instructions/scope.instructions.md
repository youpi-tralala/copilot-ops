# Scope et niveau d'autonomie — Copilot CLI

> Règle VOID : "Ce qui est critique doit être déterministe, ce qui est créatif peut être non-déterministe."
> Les contraintes ci-dessous s'appliquent **indépendamment** du contenu du prompt.

## Matrice autonomie

| Type de tâche | Mode | Validation requise |
|---|---|---|
| Lecture de fichiers, grep, glob | **Autonome** | Aucune |
| Recherche web, documentation | **Autonome** | Aucune |
| Écriture de playbook Ansible | **Co-pilote** | Lint (`/lint`) avant commit |
| Écriture de script bash | **Co-pilote** | Revue utilisateur avant commit |
| Modification fichiers YAML | **Co-pilote** | Lint avant commit |
| `git commit` / `git push` | **Co-pilote** | Confirmation explicite de l'utilisateur |
| Création / destruction de VM | **Human-in-the-loop** | Approbation explicite requise |
| Modification SSH / firewall / sudoers | **Human-in-the-loop** | Approbation explicite requise |
| Accès à la VM `code-vm` en production | **Human-in-the-loop** | Approbation explicite requise |
| Actions à l'intérieur du container éphémère lancé par `sandbox--ansible` | **Autonome** | Aucune confirmation (autorisé par l'utilisateur) |
| Toute action irréversible | **Human-in-the-loop** | Approbation explicite requise |

## Commandes autorisées sans confirmation

Ces commandes sont **autonomes** — Copilot les exécute sans demander de validation.
Toutes sont en lecture seule ou sans effet de bord.

| Commande | Usage |
|---|---|
| `rtk ls`, `rtk find` | Navigation fichiers |
| `rtk git status`, `rtk git log` | État du dépôt |
| `rtk read <file>`, `view` | Lecture de fichiers |
| `rtk grep`, `grep`, `glob` | Recherche dans les fichiers |
| `rtk gain`, `rtk gain --history`, `rtk gain --daily` | Stats RTK |
| `rtk gh repo view` | Lecture repo GitHub |
| `ssh ... "docker info"` | Vérification connectivité code-vm |
| `git diff`, `rtk diff` | Comparaison fichiers |
| `which`, `command -v` | Vérification présence d'un outil |
| `echo`, `cat /etc/os-release` | Informations système en lecture |

> Toute commande **écrivant, supprimant ou modifiant** un fichier ou une ressource requiert une validation selon la matrice ci-dessus.

- **Autonome** : Copilot exécute sans demander de confirmation.
- **Co-pilote** : Copilot propose, valide via outil (lint/sandbox), puis demande confirmation avant d'appliquer.
- **Human-in-the-loop (HITL)** : Copilot explique ce qu'il va faire, attend une approbation explicite (`oui` / `go` / `ok`) avant d'agir.

## Règles absolues (non négociables)

1. **Jamais d'auto-merge** — un humain valide toujours avant merge.
2. **Jamais d'action irréversible sans HITL** — suppression, écrasement, destruction de ressource.
3. **Toujours lint avant push** — tout fichier YAML ou playbook Ansible passe par `/lint`.
4. **Scope limité** — ne jamais accéder à des chemins hors de `access.instructions.md`.
