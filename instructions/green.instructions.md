# Bonnes pratiques Green AI

Objectif : minimiser l'empreinte environnementale de chaque interaction IA
(tokens, réseau, compute, choix de modèle).
Périmètre : toute utilisation d'IA — Copilot CLI, Claude, ChatGPT, GitHub Copilot.

Sources : [Green Software Foundation](https://principles.green) · [Green AI — Schwartz et al.](https://arxiv.org/abs/1907.10597)

---

## 1. Tokens

- **Prompts concis** : chaque token non nécessaire consomme du compute et de l'énergie.
- **Pas de contexte inutile** : n'inclure que ce qui est pertinent pour la tâche en cours.
- **RTK obligatoire** pour les sorties CLI (voir `rtk.instructions.md`).
- **Pas de répétition** : ne pas reformuler une réponse déjà donnée dans la même session.
- **Pas de remplissage** : pas d'introduction, de conclusion ou de flagornerie.
- **Réutiliser l'historique** : lire `history/` avant de redemander un contexte déjà établi.

---

## 2. Choix du modèle

> **Règle** : utiliser le modèle le plus léger suffisant pour la tâche.

| Tâche | Modèle recommandé |
|---|---|
| Recherche, grep, lookup simple | Haiku / GPT-mini |
| Rédaction, refactoring, explication | Sonnet / GPT-standard |
| Architecture complexe, raisonnement multi-étapes | Opus / GPT-large |
| Génération de code critique, sécurité | Sonnet minimum |

- Ne pas escalader vers un modèle lourd sans raison technique.
- Les sous-agents (`explore`, `task`) utilisent Haiku par défaut — ne pas forcer Sonnet sauf nécessité.

---

## 3. Réseau

- **Batching** : regrouper les appels API quand plusieurs opérations peuvent être traitées ensemble.
- **Pas d'appel redondant** : ne pas envoyer deux fois la même requête si une réponse cache est disponible.
- **Téléchargements** : utiliser `rtk wget` ou `rtk curl` pour comprimer les sorties.
- **Limiter les web_search** : chercher d'abord dans les sources locales (`grep`, `view`) avant de faire un appel réseau.

---

## 4. Compute / CPU

- **Évaluer avant d'agir** : un `grep` ou un `view` consomme infiniment moins qu'un appel LLM.
- **Pas de retry infini** : si une approche échoue deux fois, proposer une alternative plutôt que de boucler.
- **Sous-agents parcimonieux** : ne déléguer à un agent (`task`, `explore`) que si la tâche est genuinement complexe et multi-étapes.
- **Pas de background inutile** : n'utiliser `mode: background` que s'il y a un vrai travail parallèle à faire.
- **Arrêter les processus** : tuer les processus de test dès qu'ils ont rempli leur rôle.

---

## 6. Optimisations RTK identifiées en session

> Améliorations détectées via `rtk gain --history`. Mettre à jour au fil des sessions.

| Commande | Problème | Correction |
|---|---|---|
| `rtk read <file>` | 0% de gain — RTK ne filtre pas les lectures | Utiliser l'outil natif `view` à la place |
| `rtk gh repo view` | 0% — sortie JSON déjà compacte | Utiliser `gh ... \| jq` directement |
| `grep` sans préfixe | Pas filtré par RTK | Systématiser `rtk grep` pour toute recherche de contenu |
| `>/dev/null` ou `2>/dev/null` | Masque la sortie — perd le gain RTK | Ne rediriger vers null que si la sortie est vraiment inutile |

**Règle** : après chaque session, lancer `rtk gain --history` et mettre à jour ce tableau si de nouveaux patterns apparaissent.


- **LLM en dernier recours** : si une commande shell, un `grep` ou une lecture de fichier suffit, ne pas solliciter le modèle.
- **Sessions courtes et ciblées** : une session = un objectif. Éviter les sessions longues qui accumulent du contexte inutile.
- **Pas de plan pour les tâches simples** : créer un plan uniquement si la tâche implique plusieurs fichiers ou phases.
- **Fin de session propre** : mettre à jour `history/YYYY-MM-DD.md` avant de clore.
- **Transparence** : signaler à l'utilisateur si une tâche peut être accomplie sans IA.
