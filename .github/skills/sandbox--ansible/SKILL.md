---
name: sandbox--ansible
description: >
  Teste un playbook Ansible dans un container Docker éphémère sur code-vm,
  puis détruit le container. À utiliser quand on veut tester ou valider un
  playbook Ansible sans impacter un système réel.
  Invoquer avec /sandbox--ansible ou en demandant de "tester dans un sandbox ansible".

Note : actions effectuées à l'intérieur du container lancé par ce skill sont autonomes — le skill peut modifier/itérer sur les fichiers copiés dans le container sans validation utilisateur. Les sorties des commandes sont affichées intégralement.

Comportement d'exécution : le lancement du sandbox (`sandbox--ansible`) se fait en arrière-plan. Un agent effectue la copie, l'exécution et les itérations en tâche de fond; les logs et l'état d'avancement sont publiés dans `knowledge/sandbox-runs/<timestamp>/`.
allowed-tools: shell
---

## Objectif

Tester un playbook Ansible dans un container Docker éphémère sur la VM `code-vm` (192.168.56.10).

## Prérequis

- VM `code-vm` accessible via SSH (user `copilot`, clé `~/.ssh/copilot@code-vm`)
- Docker disponible sur `code-vm` (groupe docker)
- Ansible installé sur `code-vm`

## Procédure

1. Copier le répertoire du playbook à tester sur `code-vm` dans `/home/copilot/sandbox_<timestamp>/`
2. Exécuter le script `sandbox--ansible.sh` de ce répertoire en passant le chemin du playbook en argument
3. Le script crée un container Docker Debian éphémère, prépare un inventory Ansible pointant vers ce container, exécute le playbook, rapporte les résultats, puis détruit le container
4. Afficher clairement : succès/échec, tâches modifiées, erreurs éventuelles

## Connexion à code-vm

```bash
ssh -i ~/.ssh/copilot@code-vm -o StrictHostKeyChecking=no copilot@192.168.56.10
```

## Exemple d'invocation

```bash
bash /path/to/sandbox.sh /home/yves/ops/old_job/ansible-role-harden-servers
```

## Limitations

- Les tâches nécessitant systemd sont partiellement supportées (container avec `--privileged`)
- Les services ne démarrent pas automatiquement dans un container sans init
- Les tâches réseau avancées (iptables avec règles persistantes) peuvent ne pas s'appliquer correctement
