---
date: 2026-06-25
tags: [knowledge, ressource]
status: active
project: copilot-ops
type: connaissance
---

# Harness Engineering — Résumé VOID

**Source** : https://void.ma/publications/harness-engineering-agents-ia-fiables-production/
**Consulté** : 2026-06-19
**Contexte** : fondement du plan harness Copilot CLI

---

## Thèse centrale

> "Le modèle n'est plus le bottleneck. C'est le harness qui l'est."

20% prompt, 80% ingénierie autour. Les projets IA qui échouent sont presque toujours des problèmes de harness, pas de modèle.

## Les 6 piliers d'un bon harness

| Pilier | Contenu |
|---|---|
| **Contexte** | Docs, specs, historique, RAG |
| **Validation** | Tests, self-critique, evals |
| **Gouvernance** | Steering, guardrails, permissions |
| **Workflow** | Orchestration, scaffolding |
| **Observabilité** | Métriques, traces, logs |
| **Feedback loop** | Tests unitaires, intégration, E2E |

## Les 3 pièges

1. **"Le modèle est assez intelligent"** → faux. Même GPT-5 dérive sans scaffolding.
2. **"On met toutes les règles dans le prompt"** → le prompt est non-déterministe. Les contraintes critiques doivent être en dehors du LLM, dans du code déterministe.
3. **"On évaluera en production"** → trop tard. Il faut des evals avant.

## Règle d'or

> Ce qui est critique doit être **déterministe**. Ce qui est créatif peut être non-déterministe. Le harness fait la séparation.

## Leçons retenues (expérience VOID)

- Sans feedback loop automatisée (tests), pas de production.
- Limiter le scope : minor/patch uniquement en autonomie ; major → HITL.
- **Never auto-merge** — toujours un humain pour valider.
- Souveraineté = architecture, pas marketing.
- L'observabilité n'est pas optionnelle : mesurer PR proposées / mergées / rejetées.

## Stack recommandé (2026)

- Orchestration on-premise : Autogit (VOID), ou LangGraph, CrewAI
- LLM local souverain : Qwen3.5-27B / Qwen3.6-27B via Ollama / vLLM
- Validation : ansible-lint, yamllint, Playwright, pytest
- Observabilité : Langfuse, Phoenix (Arize)
