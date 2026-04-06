# ============================================================
# btrfs-snapper — Plugin Oh My Zsh pour openSUSE Tumbleweed
# Gestion enrichie btrfs et snapper
# ============================================================

# ------------------------------------------------------------
# Aliases — Raccourcis utiles (pas de doublon natif)
# ------------------------------------------------------------

# Multi-configs snapper (évite de mémoriser -c root/-c home)
alias snap-list-root='sudo snapper -c root list'
alias snap-create-root='sudo snapper -c root create --description'
alias snap-list-home='sudo snapper -c home list'
alias snap-create-home='sudo snapper -c home create --description'

# Nettoyage
alias snap-cleanup='sudo snapper cleanup number'
alias snap-cleanup-all='sudo snapper cleanup all'

# Rollback rapide (sans confirmation — usage expert)
alias rollback-last='sudo snapper rollback'

# Btrfs — contrôle scrub/balance en cours
alias btrfs-scrub-status='sudo btrfs scrub status /'
alias btrfs-scrub-cancel='sudo btrfs scrub cancel /'
alias btrfs-scrub-resume='sudo btrfs scrub resume /'
alias btrfs-balance-status='sudo btrfs balance status /'
alias btrfs-balance-pause='sudo btrfs balance pause /'
alias btrfs-balance-resume='sudo btrfs balance resume /'
alias btrfs-balance-cancel='sudo btrfs balance cancel /'

# ------------------------------------------------------------
# Fonctions enrichies — Snapper
# ------------------------------------------------------------

# Désactiver les éventuels aliases résiduels qui masqueraient les fonctions
unalias snap-list snap-new snap-del snap-rollback snap-compare 2>/dev/null
unalias btrfs-scrub btrfs-balance btrfs-balance-threshold btrfs-snap-size btrfs-health 2>/dev/null

# Liste colorée + résumé (remplace sudo snapper list)
# Vert = snapshot courant (*), Jaune = important=yes, Défaut = reste
function snap-list {
    local output
    output=$(sudo snapper list "$@")

    echo "$output" | awk '
    BEGIN {
        GREEN  = "\033[32m"
        YELLOW = "\033[33m"
        BOLD   = "\033[1m"
        RESET  = "\033[0m"
    }
    NR <= 2 { print BOLD $0 RESET; next }
    /\*/             { print GREEN  $0 RESET; next }
    /important=yes/  { print YELLOW $0 RESET; next }
    { print }
    '

    local total pre post single important
    total=$(echo "$output"    | tail -n +3 | grep -c "│" || true)
    pre=$(echo "$output"      | grep -c "│ pre    │" || true)
    post=$(echo "$output"     | grep -c "│ post   │" || true)
    single=$(echo "$output"   | grep -c "│ single │" || true)
    important=$(echo "$output"| grep -c "important=yes" || true)
    echo ""
    echo "Total : ${total} snapshots — ${single} singles, ${pre} pre, ${post} post, ${important} importants"
}

# Créer un snapshot avec description + cleanup automatique
# Usage : snap-new "avant mise à jour zypper"
function snap-new {
    if [[ -z "$1" ]]; then
        echo "Usage : snap-new <description>"
        return 1
    fi
    sudo snapper create --description "$*" --cleanup-algorithm timeline
    echo "Snapshot créé :"
    sudo snapper list | tail -1
}

# Supprimer un ou plusieurs snapshots avec affichage de la liste si absent
# Usage : snap-del 42  ou  snap-del 40-45
function snap-del {
    if [[ -z "$1" ]]; then
        echo "Usage : snap-del <id>  ou  snap-del <id1>-<id2>"
        snap-list
        return 1
    fi
    sudo snapper delete "$1"
}

# Rollback avec confirmation obligatoire
# Usage : snap-rollback 42
function snap-rollback {
    if [[ -z "$1" ]]; then
        echo "Usage : snap-rollback <id>"
        snap-list
        return 1
    fi
    echo "Attention : rollback vers snapshot $1 — êtes-vous sûr ? (o/N)"
    read -r confirm
    [[ "$confirm" =~ ^[oO]$ ]] && sudo snapper rollback "$1" || echo "Annulé."
}

# Comparer les fichiers modifiés entre deux snapshots
# Usage : snap-compare 41 42
function snap-compare {
    if [[ -z "$2" ]]; then
        echo "Usage : snap-compare <id1> <id2>"
        return 1
    fi
    sudo snapper diff "$1".."$2"
}

# Afficher uniquement les snapshots importants
function snap-important {
    sudo snapper list | awk 'NR<=2 || /important=yes/'
}

# Afficher uniquement les snapshots manuels (non zypper, non timeline)
function snap-manual {
    sudo snapper list | awk 'NR<=2 || ($0 !~ /zypp/ && $0 !~ /timeline/ && NR>2)'
}

# ------------------------------------------------------------
# Fonctions enrichies — Btrfs maintenance
# ------------------------------------------------------------

# Lancer un scrub et suivre le statut
# Usage : btrfs-scrub  ou  btrfs-scrub /mnt/data
function btrfs-scrub {
    local mount="${1:-/}"
    echo "Démarrage scrub sur $mount..."
    sudo btrfs scrub start "$mount"
    sleep 2
    sudo btrfs scrub status "$mount"
}

# Balance avec seuils configurables (défaut : 50%)
# Usage : btrfs-balance  ou  btrfs-balance 70 70
function btrfs-balance {
    local dusage="${1:-50}"
    local musage="${2:-50}"
    echo "Balance btrfs : dusage=${dusage}% musage=${musage}%"
    sudo btrfs balance start -dusage="$dusage" -musage="$musage" /
}

# Balance conditionnelle selon taux d'utilisation réel du disque
# Usage : btrfs-balance-threshold  ou  btrfs-balance-threshold 70
function btrfs-balance-threshold {
    local threshold="${1:-75}"
    local usage
    usage=$(df / | awk 'NR==2 {print $5}' | tr -d '%')
    if [[ "$usage" -gt "$threshold" ]]; then
        echo "Utilisation / : ${usage}% > ${threshold}% — lancement balance"
        sudo btrfs balance start -dusage=5 /
    else
        echo "Utilisation / : ${usage}% < ${threshold}% — balance non nécessaire"
    fi
}

# Taille réelle occupée par les snapshots (chemin openSUSE : /.snapshots/)
function btrfs-snap-size {
    echo "Taille des snapshots snapper :"
    sudo btrfs qgroup show --sort=rfer / 2>/dev/null || \
        sudo du -sh /.snapshots/*/snapshot 2>/dev/null | sort -h
}

# Rapport complet de santé btrfs
function btrfs-health {
    echo "=== Btrfs Health Report ==="
    echo ""
    echo "--- Filesystem usage ---"
    sudo btrfs filesystem usage /
    echo ""
    echo "--- Device stats (errors) ---"
    sudo btrfs device stats /
    echo ""
    echo "--- Scrub status ---"
    sudo btrfs scrub status /
    echo ""
    echo "--- Snapshots ---"
    snap-list
}
