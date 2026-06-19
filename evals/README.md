# Evals — Harness Copilot CLI

Valide que le harness fonctionne correctement avant toute montée de version.

## Exécution

```bash
bash evals/run-evals.sh
```

## Structure

| Répertoire | Contenu | Résultat attendu |
|---|---|---|
| `nominal/` | Playbook basique (install package) | ✅ Pass |
| `edge/` | Tâche avec systemd dans container | ⚠️ Échec partiel attendu (limite connue) |
| `adversarial/` | Chemin hors whitelist | ❌ Bloqué par check-paths.sh |

## Règle

Lancer `run-evals.sh` avant toute modification de `copilot-instructions.md`, d'un skill, ou d'une instruction.
