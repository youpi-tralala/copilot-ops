---
name: adhd
description: >
   Idéation divergente parallèle pour agents de code. Génère N branches isolées sous différents cadres cognitifs (régulateur, biologie, speedrunner, enfant de 10 ans, budget $0), les évalue, les regroupe, écarte les impasses et approfondit les meilleures pistes. À utiliser avec /adhd, "mode ADHD", pour brainstormer des intentions ou la conception ouverte (architecture, nommage, surface API/SDK) et pour les décisions de debug floues. Ne pas utiliser pour la syntaxe, les recherches simples, les bugs à cause connue ou les formulations fermées ("rapide", "standard", "canonique", "manuel"). Le pré‑contrôle complet est décrit dans le corps du skill.
license: MIT
date: 2026-06-25
tags: [skills, instructions]
status: active
project: copilot-ops
type: instructions
---

# ADHD

   Ne vous contentez pas de la réponse « manuel ». Les trois premières réponses
   qu'un modèle donnerait sont souvent celles qu'un ingénieur senior donnerait
   en trente secondes. Correctes, mais oubliables. Les réponses intéressantes
   viennent après la troisième, dans ce milieu inconfortable où personne ne
   va. Ce skill fait marcher le modèle dans cet espace.

   project: <https://github.com/uditakhourii/adhd>

## Pré‑contrôle (exécuter avant la Phase 1)

   Ce skill est coûteux : environ 10 appels Agent, 30 à 90s temps mur, soit
   5 à 10× une réponse unique. Ne payer ce coût que si l'exploration large est
   justifiée. Exécuter ce contrôle avant la Phase 1.

   **Étape 1. Vérification d'invocation explicite.**

   Si l'utilisateur a tapé `/adhd` ou demandé explicitement le mode ADHD,
   "utiliser le skill adhd" ou "exécuter ADHD sur ceci", **SAUTER le reste de
   cette section et aller directement en Phase 1**. L'utilisateur a choisi
   l'option ; ne pas douter.

   **Étape 2. Auto‑jugement (uniquement si l'Étape 1 ne s'applique pas).**

   Se poser trois questions. Si la réponse à l'une est non, ABANDONNER.

   1. **Ouvert ?** Un ingénieur senior donnerait-il plusieurs réponses viables
      ici, ou existe‑t‑il une réponse canonique ? Si canonique, abandonner.
   2. **À enjeux ?** Le coût d'une réponse évidente erronée est‑il élevé ?
      Décisions d'architecture, API publiques, nommage d'un produit réel,
      bugs flous sans cause connue, design de schéma = oui. Projet perso à 23h
      = non.
   3. **Formulation ouverte ?** L'utilisateur a‑t‑il évité des mots comme
      "rapide", "standard", "canonique", "manuel", "une ligne" ? S'il a
      utilisé ces mots, il veut une réponse directe. Abandonner.

   Si les trois contrôles sont validés, passer à la Phase 1.

   Si l'un échoue, ABANDONNER et répondre directement. Optionnellement ajouter
   une phrase : « Si vous voulez une exploration plus large sous cadres
   parallèles avec détection explicite des impasses, exécutez `/adhd <votre
   problème>` ».

## La boucle

   Deux phases strictes. Les mélanger tue la qualité des idées, car le
   critique étrangle le générateur.

### Phase 1 — Diverger (sans critique)

   Pour le problème P :

   1. Choisir 5 cadres cognitifs dans le tableau ci‑dessous. Favoriser les
      tags "code"/"design" pour les problèmes en lien avec le code. Inclure
      toujours au moins un cadre "wild" pour conserver de la diversité.

   2. Lancer 5 appels Agent/Task **parallèles**. Un par cadre. Chaque Agent
      reçoit seulement :
      - le problème P
      - le contexte fourni par l'utilisateur
      - l'invite (vantage prompt) du cadre choisi
      - une instruction système interdisant l'évaluation

      Instruction exacte à donner à chaque Agent :

      > You are in DIVERGENT mode. You are a generator, not a critic.
      > Generate 6 short distinct ideas under this frame. Each idea is one
      > phrase or one sentence. Do not evaluate. Do not rank. Do not hedge.
      > The first three obvious answers everyone would give are banned.
      > Push past them into the awkward middle.
      > Output a JSON array only. No prose before or after.
      > `[{"text": "...", "rationale": "..."}, ...]`

   3. **Invariant critique.** Les appels Agent doivent être parallèles et
      isolés. NE PAS les sérialiser. NE PAS passer la sortie d'une branche
      comme contexte à une autre. Les branches qui se voient s'ancrent mutuellement
      et la méthode s'effondre en une pensée élargie unique.

### Phase 2 — Converger (critique activée)

   Après réception de toutes les branches :

   1. **Noter.** Évaluer chaque idée sur trois axes 0–10 : nouveauté (écart
      par rapport au défaut évident), viabilité (peut‑elle réellement être
      livrée), adéquation (répond‑elle au problème). Pour toute idée séduisante
      mais piégeuse (coût caché, fausse économie, non scalable, abstraction
      prématurée), la marquer avec une raison en une ligne.

   2. **Regrouper.** Clusteriser les idées en 3 à 6 groupes par angle
      sous‑jacent (pas par mots‑clés de surface). Nommer les clusters par angle
      : « remove the server plays », « cache‑shaped plays », « batched‑window
      plays », etc.

   3. **Approfondir les 3 meilleures.** Classer par score pondéré
      (nouveauté 0.35 + viabilité 0.40 + adéquation 0.25), exclure les pièges,
      prendre les 3 premières. Pour chacune, lancer un appel Agent qui produit :
      - un schéma en 4–8 phrases expliquant le fonctionnement
      - le risque porteur (load‑bearing risk)
      - la première étape concrète qu'un développeur réaliserait
      - 3 à 5 idées « enfant » (variations, hybrides, unlocks)

      Instruction pour l'Agent d'approfondissement :

      > You are in FOCUS mode. Take one promising idea and connect dots.
      > Sketch how it would actually work in 4 to 8 sentences. Name the
      > load-bearing risk. Name the first concrete step a coder would take.
      > Then generate 3 to 5 sub-ideas that branch off (variations,
      > combinations with other domains, things this unlocks).
      > Output JSON only.

## Cadres (Frames)

   Choisir 5 par exécution.

   | Frame | Vantage prompt | Tags |
   |---|---|---|
   | **hardware engineer** | You think in latency, memory layout, and physical constraints. Re-ask this as a hardware/firmware problem. What does the bus topology, cache, timing budget tell you? | code, wild |
   | **regulator** | You audit systems for compliance and failure modes. What must be provable, traceable, or refusable here? | design, general |
   | **10-year-old** | You are a curious 10 year old who has never seen software. Describe naive but unencumbered approaches. Ignore convention. | general, wild |
   | **competitor trying to break it** | You are a hostile competitor or attacker. Generate approaches that exploit, fail, or sabotage the obvious solution. Then invert into ideas. | code, design |
   | **biology** | Transplant a mechanism from biology (immune systems, neural plasticity, cell signaling, evolution, gut flora). Force-fit it onto this engineering problem. | code, wild |
   | **logistics** | Steal mechanisms from logistics: queues, batching, just-in-time, hub-and-spoke, returns, last-mile. Apply them literally. | code, design |
   | **game design** | Approach this as a game designer. What are the loops, rewards, friction, save-states, speedrun tricks? Treat the user as a player. | design, general |
   | **markets** | Treat the problem as a market. Buyers, sellers, market-makers. What does an auction, a futures contract, a clearing house look like here? | design, wild |
   | **inversion** | Ask the OPPOSITE question. If goal is X, brainstorm how to guarantee NOT X. Then negate each answer back. | code, design, general |
   | **extreme: $0 budget, 1 hour** | No money, no team, one hour. What is the crudest version that still does the load-bearing thing? | code, general |
   | **extreme: infinite budget, 10 years** | Infinite compute, infinite engineers, a decade. What is the maximalist version? | design, wild |
   | **remove the load-bearing assumption** | Name the thing everyone treats as fixed (framework, database, request-response model, network). Imagine it is gone. What is possible? | code, design, wild |
   | **speedrunner** | You are a speedrunner. Find glitches, skips, out-of-bounds tricks, frame-perfect shortcuts. What is the abusive-but-legal path? | code, wild |
   | **ant colony** | No central planner. Many dumb agents, local rules, pheromone trails. How does the problem solve itself emergently? | code, wild |
   | **3am on-call** | You are the on-call engineer woken at 3am when this breaks. What design would let you not get paged? | code, design |

### Choisir les cadres

   Pour les problèmes liés au code : choisir 4 cadres taggés `code` ou `design`, plus
   1 taggé `wild`. Pour les problèmes produit/strat ouverts : mélanger.
   Varier les choix entre exécutions pour obtenir des ensembles différents.

## Format de sortie

   Après la Phase 2, rendre dans cet ordre. Ne pas tout condenser en un mur de
   texte : la structure compte.

   1. **Bref.** Une ou deux lignes confirmant le problème et la reformulation.
   2. **Ensemble large.** Pool complet regroupé par cluster. Chaque cluster
      nommé par son angle. Chaque idée en une courte phrase. Afficher les
      étiquettes de score comme `[N7 V8 F9]` à côté de chaque idée.
   3. **Convergence.** Une shortlist de 2 à 4 idées. Expliquer pourquoi chaque
      idée est sur la liste. Marquer explicitement le choix non‑évident mais
      viable par ★. Lister séparément les pièges, chacun avec la raison en
      une ligne.
   4. **Focus.** Les 3 branches approfondies. Pour chacune : le schéma, le
      risque porteur, la première étape concrète, et les idées enfant.
   5. **Provocation.** Une question ou idée wildcard qui ouvre une nouvelle
      direction si rien n'a convaincu.

## Anti‑patterns

   Ceux qui font échouer ce skill. Les surveiller.

- **Convergence déguisée en divergence.** Dix variations mineures d'une
     même idée ne constituent pas de la largeur. Si chaque candidat partage
     la même hypothèse sous‑jacente, vous n'avez pas divergé. Vous avez
     décoré.
- **Étrange pour l'étrange sans convergence.** Un tas de 30 absurdités non
     triées est aussi inutile qu'une réponse sûre. Converger.
- **Murs de prose équivalente.** Clusteriser, étiqueter, extraire le meilleur.
     La structure vaut la moitié de la valeur.
- **Refus de s'engager.** Après avoir divergé, prendre position sur ce qui
     est prometteur. « Voici 20 idées, décider vous‑même » est lâche. Générer
     large, mais converger avec une opinion réelle.
- **Sauter l'invariant d'isolation.** Si vous simulez des branches parallèles
     en les écrivant séquentiellement dans un même contexte, vous n'avez pas
     fait ADHD. Vous avez produit une pensée élargie unique. L'Agent/Task
     tool donne à chaque branche un contexte neuf. Utilisez‑le.

## Calibration

- **Combien d'idées ?** Adapter aux enjeux. "Nommer cette fonction" =
     3 frames × 4 idées. "Comment positionner ce produit" = 5 frames × 8
     idées. Par défaut 5 × 6 = 30.
- **À quel point étrange ?** Lire la salle. Travail stratégique sérieux :
     marquer clairement les wildcards. Brainstorm ouvert ou jeu : laisser
     courir. Les idées absurdes méritent leur place si elles engendrent des
     idées viables.
- **Quand arrêter de diverger ?** Arrêter quand les nouveaux candidats
     répètent la forme des existants. L'espace est cartographié. Ne pas
     gonfler juste pour atteindre un nombre.

## Coût

   5 diverge + 1 score + 1 cluster + 3 deepen ≈ 10 appels Agent par exécution.
   Environ 5 à 10× une réponse unique. À réserver aux points de décision où
   le coût d'une réponse évidente est élevé.

## Bibliothèque compagnon et CLI

   Il existe une implémentation Node/TS qui réalise la même boucle avec
   parsage JSON structuré, pondération des scores et CLI. L'utiliser hors
   Claude Code ou en batch.

       npm install -g adhd-agent
       adhd "votre problème ici"

   Code, article, évaluations et guide de contribution :
   <https://github.com/UditAkhourii/adhd>. Le skill ci‑dessus fournit la même
   boucle dans Claude sans installation.

## Spécification source

   Ce skill opérationnalise une spécification écrite sur l'idéation
   divergente. Le texte original est conservé dans `SOURCE-SPEC.md` pour
   référence. Les choix d'implémentation retenus ici (appels Agent parallèles
   isolés, séparation mécanique générateur/critique, branching par cadres)
   proviennent de cette spécification.
