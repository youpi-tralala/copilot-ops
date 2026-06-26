---
date: 2026-06-25
tags: [instructions, politique]
status: active
project: copilot-ops
type: instructions
---

# Bonnes pratiques Green AI

Objectif : réduire l'empreinte environnementale des développements et des interactions IA (tokens, réseau, compute, choix de modèles). S'applique au travail local, aux playbooks, CI/CD et aux agents.

Sources : Green Software Foundation · Green AI (Schwartz et al.) · greencoding.agent.md (référence interne)

---

## Principes clés (résumé)

- Mesurer avant d'optimiser : profiler et collecter métriques (CPU, mémoire, I/O, réseau, SCI si possible).
- Prioriser les changements par impact mesurable (gain SCI vs coût de maintenance).
- Tester toute modification critique en sandbox (`sandbox--ansible`) avant push.
- Favoriser les optimisations d'architecture (batching, cache, pagination) avant micro‑optimisations.
- Préserver lisibilité et sécurité : ne pas sacrifier compréhension ou sécurité pour un gain minime.

---

## 1. Tokens et prompts

- Prompts concis et ciblés. Éviter d'envoyer l'historique complet inutilement.
- Réutiliser `history/` et `knowledge/` pour contexte local.
- RTK obligatoire pour commandes CLI sortant beaucoup de texte (voir `rtk.instructions.md`).
- LLM en dernier recours : préférez grep/view/outil local.

---

## 2. Modèles et coût compute

- Utiliser le modèle le plus léger suffisant pour la tâche (ex: Haiku pour recherches, Sonnet pour refactorings).
- Éviter d'itérer inutilement contre un modèle coûteux.
- Documenter choix de modèle et justification dans les PRs quand impact significatif.

---

## 3. Réseau et données

- Grouper requêtes (batching) et compresser payloads.
- Préférer formats efficaces (protobuf/msgpack) si applicable.
- Limiter téléchargements et appels externes en localisant informations dans `knowledge/`.

---

## 4. Code & infra : stratégie d'optimisation

1. Profile (py-spy, perf, pprof, flamegraphs) → identifier hotspots.
2. Analyser fréquence d'exécution et criticité (scale vs batch).
3. Proposer alternatives (algorithme, cache, pagination, dénormalisation, right‑sizing infra).
4. Implémenter tests et mesurer avant/après (temps, mémoire, SCI approximé).
5. Rédiger justification et instructions de rollback dans la PR.

Anti‑patterns prioritaires à corriger : busy‑wait, N+1 queries, chargement de datasets complets, copies profondes inutiles, blocking I/O sur chemins critiques.

---

## 5. KPI & suivi

Mesurer et suivre : SCI (si possible), énergie par transaction (mWh), CPU utile vs overhead, mémoire max, débit/latence, bytes transférés.
Ajouter métriques dans observability (Grafana/Prometheus) quand pertinent.

---

## 6. Sandbox & CI rules (intégration avec `sandbox--ansible`)

- Tout playbook ou changement infra doit être testé via `sandbox--ansible` avant push.
- Les modifications de playbooks / YAML : lint + sandbox run obligatoires (voir `skills/Ansible Lint Skill`).
- Les runs sandbox produisent des dossiers `knowledge/sandbox-runs/<timestamp>/` — lier ces artefacts à la PR.

---

## Checklist rapide (avant push)

- [ ] Profiling initial effectué
- [ ] Gain estimé et justification documentés
- [ ] Tests unitaires/integrations verts
- [ ] Sandbox run OK (logs + artefacts attachés)
- [ ] CI léger (batching/limits) activé si nécessaire
- [ ] PR documente métriques before/after

---

Notes : conserver ce fichier à jour avec `rtk gain --history` et la FAQ interne `greencoding.agent.md`. Pour tout doute sur priorisation, demander une revue ciblée (HITL) avant changement irréversible.

---

## Headroom Proxy

Headroom peut réduire considérablement la consommation de tokens pour les appels LLM. Recommandations :

- Démarrer automatiquement à chaque début de session le proxy localement pour les environnements de développement : `headroom proxy --port 8787`.
- Pointer les clients vers le proxy :
  - OpenAI-compatible clients : `export OPENAI_BASE_URL=http://localhost:8787/v1`
  - Anthropic/Claude : `export ANTHROPIC_BASE_URL=http://localhost:8787`
- Vérifier les statistiques : `rtk curl http://localhost:8787/stats`.
- Sécuriser l'accès : bind sur localhost ou utiliser firewall / reverse proxy avec auth si exposé.

Intégration CI / services : injecter les variables d'environnement ci‑dessus dans les services (docker-compose, systemd unit, containers) pour forcer le routage via Headroom.

Rapports : utiliser le template HISTORY_AUTO standard dans `.github/history/YYYY-MM-DD.md`.

### Affichage human‑readable et consolidation

- Le fichier `.github/history/YYYY-MM-DD.md` consolide tout en un seul document au format :
  - `### Green Stats` (efficacité, volumes, tokens, cas d'usage)
  - `## Sujets abordé N` avec sources/actions/blocages/prochaines actions
- Mise à jour automatique : toutes les  heures
- Format : sections markdown avec blocs de données parsées (lisibles)
- Pas de fichiers compagnons séparés (`.headroom.json`, `.headroom.txt`) — tout consolidé dans le `.md`

Template attendu :

```markdown
# Session YYYY-MM-DD

---

<!-- HISTORY_AUTO_START -->
## Méta

### Green Stats 
- outil utilisés:
- efficacite_estimee_pct:
- total_number_of_sessions:
- total_requetes:
- total_tokens:
- total_tokens_saved:
- cas_usage_observes:
- proxy_inbound_total:

## Sujets abordé X

### Contexte
### Sources consultées (interne / externe)
### Actions réalisées
### Problèmes / Blocages
### Prochaines actions recommandées

## Sujets abordé Y

### Contexte
### Sources consultées (interne / externe)
### Actions réalisées
### Problèmes / Blocages
### Prochaines actions recommandées
<!-- HISTORY_AUTO_END -->
```

### Parsing des stats

- La sortie JSON de `/stats` doit être parsée avec `jq` pour formatage et extraction des champs avant insertion dans le rapport consolidé.

Exemples :

- `rtk curl -sS http://localhost:8787/stats | jq '.'`  # pretty-print / filtrage avec jq

- Pour extraire uniquement tokens_saved :
  - `rtk curl -sS http://localhost:8787/stats | jq '.tokens.saved'`

### Mise à jour périodique (opérationnelle)

- Un processus d'actualisation en arrière‑plan met à jour `.github/history/YYYY-MM-DD.md` toutes les 30 minutes (intervalle configurable).
- Chaque mise à jour consolide :
  - Green Stats (dérivées de stats parsées avec `jq`)
  - Sujets abordés et actions
- Chaque mise à jour est consignée dans `knowledge/headroom_updates.log` (horodatée).
- Aucun fichier compagnon séparé (`.headroom.json`, `.headroom.txt`, `_generated_updates.md`) — tout dans le `.md` consolidé.

- Toute exposition réseau (liaison non‑localhost) nécessite approbation explicite.
