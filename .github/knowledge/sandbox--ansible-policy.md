---
date: 2026-06-25
tags: [knowledge, ressource]
status: active
project: copilot-ops
type: connaissance
---

# Sandbox--ansible — Policy et log des droits

Consulté/Créé : 2026-06-19

## Politique

- Le skill `sandbox--ansible` lance un container Docker éphémère sur `code-vm` et copie le code de test dans `/ansible` (mount).  
- L'utilisateur a autorisé Copilot à effectuer toute modification à l'intérieur de ce container sans demande de confirmation.  
- Conséquence : Copilot peut itérer librement (modifier playbooks/rôles dans le container, relancer playbook, corriger, retester).  
- Les actions restent confinées au container éphémère : rien n'est poussé automatiquement vers des dépôts distants sans confirmation humaine.

## Procédure opératoire

1. Copier le repo/role dans /ansible du container
2. Exécuter `ansible-playbook` (connection=local)
3. En cas d'erreur, modifier le code dans /ansible, rerun, itérer
4. À la fin, rapport détaillé : erreurs, modifications appliquées, sorties de commandes
5. Tout est consigné dans `knowledge/` (log + diffs)

