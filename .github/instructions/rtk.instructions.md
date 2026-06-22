# Instructions RTK — Économie de tokens

RTK (Rust Token Killer) est installé dans `~/.local/bin/rtk`.
Il réduit de 60 à 90 % les tokens consommés par les sorties CLI.

> **Règle** : préfixer systématiquement les commandes ci-dessous par `rtk` dans les appels bash.

## Substitutions obligatoires

| Commande native | Commande RTK |
|---|---|
| `git <cmd>` | `rtk git <cmd>` |
| `gh <cmd>` | `rtk gh <cmd>` |
| `docker <cmd>` | `rtk docker <cmd>` |
| `kubectl <cmd>` | `rtk kubectl <cmd>` |
| `ls <path>` | `rtk ls <path>` |
| `find <args>` | `rtk find <args>` |
| `grep <args>` | `rtk grep <args>` |
| `diff <args>` | `rtk diff <args>` |
| `curl <args>` | `rtk curl <args>` |
| `wget <args>` | `rtk wget <args>` |
| `cat <file>` | `rtk read <file>` |
| `pip <cmd>` | `rtk pip <cmd>` |
| `npm <cmd>` | `rtk npm <cmd>` |
| `go <cmd>` | `rtk go <cmd>` |

## Commandes utilitaires RTK

```bash
rtk err <cmd>        # affiche uniquement les erreurs/warnings
rtk test <cmd>       # affiche uniquement les échecs de tests
rtk summary <cmd>    # résumé heuristique en 2 lignes
rtk json <file>      # JSON compact
rtk log <cmd>        # filtre et déduplique les logs
```

## Stats de consommation

```bash
rtk gain             # économies de la session
rtk gain --history   # historique des commandes
rtk gain --graph     # graphique ASCII 30 jours
rtk gain --daily     # jour par jour
```

## Exceptions (ne pas préfixer)

- Commandes interactives nécessitant stdin (ex: `gh auth login`)
- Commandes dont la sortie brute est nécessaire pour parsing (`jq`, `awk`, etc.)
- Dans ce cas, utiliser `rtk proxy <cmd>` pour exécuter sans filtrage
