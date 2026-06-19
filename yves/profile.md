# Profil technique — Yves

> Mis à jour au fil des sessions. Basé sur les échanges, les questions posées, les problèmes résolus, et l'analyse du répertoire `ops`.

## Stack de travail

| Couche | Technologie |
|---|---|
| OS hôte | Windows 11 + WSL2 (Debian) |
| Virtualisation | VirtualBox + Vagrant |
| VM principale | Debian Bookworm (`code-vm`, 192.168.56.10) |
| Réseau VM | eth0 NAT + eth1 host-only |
| Config mgmt | Ansible |
| Conteneurs | Docker / Podman |
| Cloud | Azure (CLI, bases) |
| IaC | Terraform (en apprentissage) |
| Éditeur | Neovim (LSP) + VSCode |
| Shell | bash / fish / PowerShell |
| Documentation | Obsidian (Markdown + Mermaid) |

## Compétences acquises

### Linux & Administration système
- Administration Debian/Ubuntu : packages apt, systemd, utilisateurs/groupes
- SSH : clés ed25519, `config.d`, X11 forwarding, hardening, `authorized_keys`
- Services : nginx, certbot, fail2ban, PostgreSQL, Oracle, Jetty, LDAP
- CA corporate : injection de certificats Zscaler
- Outils : `tcpdump`, `ss`, `ip`, `iptables`, `journalctl`, `btop`, `jq`, `yq`, `tree`

### Réseau & Sécurité
- Modèle réseau L2/L3 : interfaces, NAT vs host-only
- `iptables` : règles INPUT, INSERT/DELETE dynamique
- Port knocking (`knockd`) : séquence, config par interface (bug eth0/eth1 diagnostiqué et résolu)
- Debug par isolation de couche : client → réseau → interface → daemon → firewall

### Virtualisation
- Vagrant : cycle de vie VM, Vagrantfile, provisioning shell, variables externes YAML
- VirtualBox shared folders : modèle de permissions au montage (`dmode`, `fmode`, `uid`, `gid`)
- Limites vboxsf : pas de POSIX par fichier, `chmod`/`chown` ignorés — pattern séparation code/runtime
- Debug VirtualBox : suppression VM zombie via `VBoxManage`
- Docker / Podman : containers éphémères, images

### Ansible
- Structure projet : `{playbooks,roles/<role>}`, `lookup_paths`
- Modules : `file`, `copy`, `lineinfile`, `blockinfile`, `user`, `apt`, `shell`, `template`, `authorized_key`, `npm`, `get_url`
- `vars_files`, inventories `.ini`, `ansible_ssh_common_args`
- Pièges résolus : répertoire world-writable, inventory mal formé, chemins relatifs des rôles

### Scripting & Automatisation
- Bash : `set -euo pipefail`, orchestration multi-outils (`run.sh`)
- `yq` pour parser YAML en shell
- PowerShell : bases Windows

### Cloud & IaC
- Azure CLI : installation, bases
- Terraform : notions (en progression)

## Points de vigilance identifiés dans le code

- **Secrets dans `global_vars.yml`** : fichier exclu du dépôt via `.gitignore` ✅ — à terme, migrer vers Ansible Vault pour chiffrer en local également
- Quelques tâches Ansible utilisent `shell/command` là où des modules idempotents existent
- Tâches redondantes dans le playbook (locks apt, `ntpdate` appelé deux fois)

## Méthode de travail observée

- Approche **debug par isolation de couche**
- Utilise M365 Copilot Chat + Copilot CLI en parallèle
- Préfère comprendre le "pourquoi" avant d'appliquer
- Travaille depuis WSL, évite Windows pour les opérations Linux/réseau
- Documentation dans Obsidian (Markdown/Mermaid)
