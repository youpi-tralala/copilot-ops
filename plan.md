# Plan — Harness Engineering pour Copilot CLI

## Diagnostic : état actuel du harness

> Inspiré de l'article VOID : "Le modèle n'est plus le bottleneck. C'est le harness qui l'est."

| Pilier | État | Problème |
|---|---|---|
| **Contexte** | 🟡 Partiel | instructions.md + profil + history/ — pas de contexte projet courant |
| **Feedback loop** | 🔴 Absent | Skill sandbox défini mais SSH container non résolu |
| **Guardrails** | 🟡 Non-déterministe | access.instructions.md dans le prompt — LLM peut l'ignorer |
| **Workflow / Scope** | 🟡 Partiel | Pas de distinction autonome vs human-in-the-loop |
| **Observabilité** | 🟡 Partiel | RTK stats + history/ narratif — pas de métriques structurées |
| **Evals** | 🔴 Absent | Aucun cas de test nominal ou adversarial |

### Leçon clé VOID appliquée au contexte

> "Un agent qui corrige du code mais ne peut pas vérifier que ça marche, c'est un agent qui fabrique des bombes à retardement."

Dans notre cas : Copilot écrit des playbooks Ansible sans les tester. Le skill sandbox existe mais n'est pas opérationnel.  
**Priorité absolue = débloquer la boucle de feedback.**

---

## Phase 1 — Feedback loop (priorité absolue)

**Objectif** : Copilot peut tester ce qu'il écrit avant de le soumettre.

### 1.1 Débloquer le skill sandbox

Problème connu : SSH container dans Docker non résolu (sessions précédentes).  
Approche alternative : utiliser `docker exec` directement (sans SSH) — plus simple, moins fragile.

**Fichiers à modifier :**
- `skills/code-sandbox/sandbox.sh` — remplacer le channel SSH par `docker exec`
- `skills/code-sandbox/SKILL.md` — mettre à jour la procédure

**Logique cible :**
```
1. scp playbook → code-vm
2. docker run debian:bookworm --privileged
3. docker exec → pip install ansible
4. docker exec → ansible-playbook -i inventory (connexion locale dans le container)
5. rapport succès/échec
6. docker rm
```

### 1.2 Lint automatique avant push

Ajouter un skill `lint` qui valide avant tout commit :
- `ansible-lint` sur les playbooks Ansible
- `yamllint` sur tous les fichiers YAML

**Fichiers à créer :**
- `skills/lint/SKILL.md`
- `skills/lint/lint.sh`

**Règle à ajouter dans `copilot-instructions.md`** :
> Avant tout `git push` sur un playbook Ansible ou fichier YAML, invoquer le skill lint.

---

## Phase 2 — Guardrails déterministes

**Objectif** : les contraintes critiques sortent du prompt (non-déterministe) et entrent dans du code (déterministe).

> Règle VOID : "Ce qui est critique doit être déterministe, ce qui est créatif peut être non-déterministe."

### 2.1 Script de validation des chemins

Créer `skills/guardrails/check-paths.sh` :  
Avant toute écriture de fichier, vérifie que le chemin est dans la whitelist de `access.instructions.md`.  
Si hors whitelist → exit 1 + message explicite.

### 2.2 Matrice autonomie / HITL

Ajouter `instructions/scope.instructions.md` définissant explicitement :

| Type de tâche | Mode | Validation |
|---|---|---|
| Écriture playbook Ansible | Co-pilote | Lint + sandbox avant commit |
| Commit / push | Co-pilote | Toujours confirmer avec l'utilisateur |
| Création/destruction VM | Human-in-the-loop | Approbation explicite requise |
| Modification SSH / firewall | Human-in-the-loop | Approbation explicite requise |
| Lecture de fichiers | Autonome | Aucune |
| Recherche / grep | Autonome | Aucune |

---

## Phase 3 — Evals

**Objectif** : valider que le harness fonctionne sur des cas connus avant de l'utiliser sur du vrai code.

> Leçon VOID : "Il faut une suite d'evals avant production — cas nominaux, cas limites, cas adversariaux."

### 3.1 Créer `evals/`

```
evals/
├── README.md           — comment exécuter les evals
├── nominal/
│   └── playbook-simple.yml     — playbook basique, doit passer
├── edge/
│   └── role-avec-systemd.yml   — limite connue du sandbox
└── adversarial/
    └── touch-interdit.yml      — tente d'écrire hors whitelist, doit échouer
```

### 3.2 Script `evals/run-evals.sh`

Exécute tous les cas, produit un rapport pass/fail.  
Invoquer avant toute montée de version du harness.

---

## Phase 4 — Observabilité structurée

**Objectif** : mesurer pour savoir si le harness progresse ou dérive.

> Leçon VOID : "On mesure chaque semaine : PR proposées, PR mergées, PR rejetées."

### 4.1 Format history/ structuré

Ajouter en fin de chaque fichier `history/YYYY-MM-DD.md` une section YAML :

```yaml
metrics:
  taches_realisees: 4
  succes: 3
  echecs: 1
  fichiers_modifies: ["skills/sandbox.sh", "copilot-instructions.md"]
  sandbox_utilise: true
  lint_utilise: false
```

### 4.2 Script de synthèse

`skills/observability/weekly-report.sh`  
Parse les sections `metrics:` des 7 derniers fichiers history/ et affiche un tableau récapitulatif.

---

## Ordre d'implémentation

1. **Phase 1.1** — sandbox sans SSH (déblocage immédiat du feedback)
2. **Phase 1.2** — skill lint (validation automatique)
3. **Phase 2.2** — scope.instructions.md (guardrails légers mais immédiats)
4. **Phase 2.1** — check-paths.sh (guardrail déterministe)
5. **Phase 3** — evals (une fois le sandbox opérationnel)
6. **Phase 4** — observabilité (en dernier, quand le reste est stable)

---

## Ce qu'on ne fait PAS (scope hors périmètre)

- RAG sur les projets (trop complexe, pas de ROI immédiat)
- LLM-as-a-judge (hors budget compute)
- Auto-merge (jamais — règle VOID applicable ici aussi)

---

## Mise à jour — 2026-06-19 (état d'avancement)

Travail réalisé :
- Phase 1.2 : skill `lint` ajouté (skills/Ansible Lint Skill/*) — scripts et SKILL.md créés
- Phase 2.1/2.2 : `check-paths.sh` implémenté et `instructions/scope.instructions.md` ajouté/MAJ
- Phase 3 : `evals/` ajouté (nominal/edge/adversarial + run-evals.sh)
- Phase 4 : `skills/observability/weekly-report.sh` ajouté
- Knowledge base : `knowledge/` créé et `harness-engineering-void.md` + `sandbox--ansible-policy.md` ajoutés
- Sandbox : `skills/sandbox--ansible/sandbox--ansible.sh` (refactor docker-exec) et SKILL.md mis à jour; agent `sandbox-runner` lancé en arrière-plan
- Repo : tous les changements commités et pushés vers https://github.com/youpi-tralala/copilot-ops (commits récents: 35fd948, d3849f1, 0c5566a)

Artefacts et emplacements :
- Repo instructions : /home/yves/ops/my_git/copilot-ops/
- Knowledge runs (en cours) : /home/yves/ops/my_git/copilot-ops/knowledge/sandbox-runs/<timestamp>/
- Plan de session : {plan.md} (ce fichier)

Prochaines actions recommandées :
1. Laisser l'agent sandbox-runner terminer (ou lire progress.log dans knowledge/sandbox-runs/<ts>/)
2. Examiner les summaries dans knowledge/ puis intégrer corrections sûres upstream manuellement
3. Automatiser les tests E2E (Playwright) si besoin pour remonter le niveau de confiance

Si tu veux, je finalise le rapport consolidé (1 page) et ferme le plan ; sinon on passe au nouveau sujet.
