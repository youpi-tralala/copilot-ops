---
date: 2026-06-25
tags: [instructions, politique]
status: active
project: copilot-ops
type: instructions
---

# Scope et niveau d'autonomie — Copilot CLI

> Règle VOID : "Ce qui est critique doit être déterministe, ce qui est créatif peut être non-déterministe."
> Les contraintes ci-dessous s'appliquent **indépendamment** du contenu du prompt.

## Matrice autonomie

| Type de tâche                                                            | Mode                  | Validation requise                               |
| ------------------------------------------------------------------------ | --------------------- | ------------------------------------------------ |
| Lecture de fichiers, grep, glob                                          | **Autonome**          | Aucune                                           |
| Recherche web, documentation                                             | **Autonome**          | Aucune                                           |
| Écriture de playbook Ansible                                             | **Co-pilote**         | Lint (`/lint`) avant commit                      |
| Écriture de script bash                                                  | **Co-pilote**         | Revue utilisateur avant commit                   |
| Modification fichiers YAML                                               | **Co-pilote**         | Lint avant commit                                |
| `git commit` / `git push`                                                | **Co-pilote**         | Confirmation explicite de l'utilisateur          |
| Création / destruction de VM                                             | **Human-in-the-loop** | Approbation explicite requise                    |
| Modification SSH / firewall / sudoers                                    | **Human-in-the-loop** | Approbation explicite requise                    |
| Accès à la VM `code-vm` en production                                    | **Human-in-the-loop** | Approbation explicite requise                    |
| Actions à l'intérieur du container éphémère lancé par `sandbox--ansible` | **Autonome**          | Aucune confirmation (autorisé par l'utilisateur) |
| Toute action irréversible                                                | **Human-in-the-loop** | Approbation explicite requise                    |

## Commandes autorisées sans confirmation

Ces commandes sont **autonomes** — Copilot les exécute sans demander de validation.
Toutes sont en lecture seule ou sans effet de bord.

| Commande                                             | Usage                             |
| ---------------------------------------------------- | --------------------------------- |
| `rtk ls`,`rtk ls -la`, `rtk find`                    | Navigation fichiers               |
| `rtk git status`, `rtk git log`                      | État du dépôt                     |
| `rtk read <file>`, `view`                            | Lecture de fichiers               |
| `rtk grep`, `grep`, `glob`                           | Recherche dans les fichiers       |
| `rtk gain`, `rtk gain --history`, `rtk gain --daily` | Stats RTK                         |
| `rtk gh repo view`                                   | Lecture repo GitHub               |
| `ssh ... "docker info"`                              | Vérification connectivité code-vm |
| `git diff`, `rtk diff`                               | Comparaison fichiers              |
| `which`, `command -v`                                | Vérification présence d'un outil  |
| `which`, `command -v`                                | Vérification présence d'un outil  |
| `rtk wc -l`, `rtk wc -w`, `rtk wc -c`                | Comptage lignes/mots/caractères   |
|     /|       |

> Toute commande **écrivant, supprimant ou modifiant** un fichier ou une ressource requiert une validation selon la matrice ci-dessus.

- **Autonome** : Copilot exécute sans demander de confirmation.
- **Co-pilote** : Copilot propose, valide via outil (lint/sandbox), puis demande confirmation avant d'appliquer.
- **Human-in-the-loop (HITL)** : Copilot explique ce qu'il va faire, attend une approbation explicite (`oui` / `go` / `ok`) avant d'agir.

## Règles absolues (non négociables)

1. **Jamais d'auto-merge** — un humain valide toujours avant merge.
2. **Jamais d'action irréversible sans HITL** — suppression, écrasement, destruction de ressource.
3. **Toujours lint avant push** — tout fichier YAML ou playbook Ansible passe par `/lint`.
4. **Scope limité** — ne jamais accéder à des chemins hors de `access.instructions.md`.

## Droit d'exécution Headroom

Pour permettre au Copilot CLI de démarrer le proxy Headroom en début de session, d'exporter les variables nécessaires, et d'exécuter un updater périodique qui met à jour `knowledge/`, `history/` et les fichiers d'instructions générés, les droits minimaux suivants sont requis sur le dépôt `copilot-ops` (et ses scripts d'exécution) :

- Permission d'exécution des scripts `headroom`/`rtk` dans l'environnement utilisateur (installation via pipx ou pip).
- Droit d'exécution et de lecture sur les scripts d'initialisation présents dans `.github/scripts/`.
- Autorisation pour le processus utilisateur courant de lancer des services locaux (bind sur localhost :8787) et de lancer des processus utilisateur en arrière‑plan.

Comportement :

- Au démarrage de session, Copilot vérifie la présence de `headroom` et doit lancer `headroom proxy --port 8787` si l'exécutable est disponible.
- Copilot exportera les variables d'environnement suivantes pour les sessions locales :
  - `OPENAI_BASE_URL=http://localhost:8787/v1`
  - `ANTHROPIC_BASE_URL=http://localhost:8787`
- Le processus updater (optionnel) pourra être lancé en arrière‑plan par Copilot pour exécuter les tâches périodiques (intervalle configurable via `HEADROOM_UPDATE_INTERVAL`, par défaut 300s). Le processus doit être détaché et limité à l'utilisateur courant.

Sécurité : ces actions restent limitées à l'utilisateur courant et au bind sur localhost par défaut. Toute ouverture réseau ou exposition publique nécessite approbation explicite.

