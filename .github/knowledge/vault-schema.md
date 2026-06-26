---
date: 2026-06-25
tags: [vault, frontmatter, obsidian, gouvernance]
status: active
project: copilot-ops
type: instructions
---

# Schema vault

Hub principal: [[.github/knowledge/vault-index]]

## Frontmatter obligatoire

Chaque fichier Markdown actif doit commencer par:

```yaml
---
date: YYYY-MM-DD
tags: [tag1, tag2]
status: active|draft|archived
project: copilot-ops|<autre-projet-long-terme>
type: instructions|connaissance|ressource|journal|rapport|runbook
---
```

## Taxonomie FR (liste fermee)

### status

- active
- draft
- archived

### type

- instructions
- connaissance
- ressource
- journal
- rapport
- runbook

### tags racines recommandees

- instructions
- politique
- evals
- sandbox
- observabilite
- headroom
- knowledge
- vault
- rtk
- securite

## Convention de liens

- Lien interne: `[[chemin/vers/note]]` obligatoire.
- Backlink minimal: chaque note `status: active` doit lier au moins un hub:
  - [[.github/knowledge/vault-index]]
  - [[.github/copilot-instructions]]

## Regles d'apprentissage continu

- Capture: en fin de session + checkpoint horaire.
- Stockage canonique: Markdown-first (pas de DB obligatoire en phase 1).
- Sources d'autorite: conserver les references dans la note ou dans la note hub associee.

## Perimetre de migration

- Tous les fichiers Markdown versionnes du repo suivent ce schema.
