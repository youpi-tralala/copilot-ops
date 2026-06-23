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

- Démarrer le proxy localement pour les environnements de développement : `headroom proxy --port 8787`.
- Pointer les clients vers le proxy :
  - OpenAI-compatible clients : `export OPENAI_BASE_URL=http://localhost:8787/v1`
  - Anthropic/Claude : `export ANTHROPIC_BASE_URL=http://localhost:8787`
- Vérifier les statistiques : `rtk curl http://localhost:8787/stats`.
- Sécuriser l'accès : bind sur localhost ou utiliser firewall / reverse proxy avec auth si exposé.

Intégration CI / services : injecter les variables d'environnement ci‑dessus dans les services (docker-compose, systemd unit, containers) pour forcer le routage via Headroom.

Rapports : inclure la sortie de `/stats` dans les rapports quotidiens (`.github/history/YYYY-MM-DD.md`) sous la clé `headroom_stats`.

### Parsing des stats

- La sortie JSON de `/stats` doit être parsée avec `jk` pour formatage et extraction des champs avant insertion dans les rapports.
- Si `jk` absent, utiliser `jq` en fallback.

Exemples :

- `rtk curl -sS http://localhost:8787/stats | jk`  # pretty-print / filtrage avec jk
- fallback : `rtk curl -sS http://localhost:8787/stats | jq '.'`

- Pour extraire uniquement tokens_saved avec jk (ou jq) :
  - `rtk curl -sS http://localhost:8787/stats | jk`  # afficher puis copier le champ nécessaire
  - `rtk curl -sS http://localhost:8787/stats | jq '.tokens.saved'`  # si jq utilisé


