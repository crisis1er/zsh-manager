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

# Create a fully interactive guided snapshot
# Features: banner + scenario menu + disk check + context + root/home/both + colored feedback
# Usage: snap-new
function snap-new {
    local RED="\033[31m" GREEN="\033[32m" YELLOW="\033[33m"
    local CYAN="\033[36m" BOLD="\033[1m" RESET="\033[0m"

    # 0. Welcome banner
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║${RESET}${BOLD}              Snap-New — SafeITExperts                        ${RESET}${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET}              Guided Snapshot Creation                        ${CYAN}║${RESET}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${RESET}"
    echo -e "${CYAN}║${RESET}  You are about to create a snapshot of your system.          ${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET}                                                              ${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET}  A snapshot captures the current state of your filesystem.   ${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET}  If something goes wrong, you can roll back to this point.   ${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET}                                                              ${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET}  ${YELLOW}→${RESET} Choose ${YELLOW}Important${RESET} if you're about to make a significant    ${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET}    change (update, install, config, downgrade)               ${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET}  ${GREEN}→${RESET} Choose ${GREEN}Standard${RESET} for routine checkpoints                   ${CYAN}║${RESET}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # 1. Reason — 2-column scenario table (7 Important / 7 Standard)
    echo -e "${CYAN}┌───────────────────────────────┬──────────────────────────────┐${RESET}"
    echo -e "${CYAN}│${RESET}${BOLD}${YELLOW}  Important                    ${RESET}${CYAN}│${RESET}${BOLD}${GREEN}  Standard                    ${RESET}${CYAN}│${RESET}"
    echo -e "${CYAN}├───────────────────────────────┼──────────────────────────────┤${RESET}"
    echo -e "${CYAN}│${YELLOW}  1. Before system update      ${CYAN}│${GREEN}  8. Routine checkpoint       ${CYAN}│${RESET}"
    echo -e "${CYAN}│${YELLOW}  2. Before kernel change      ${CYAN}│${GREEN}  9. After successful test    ${CYAN}│${RESET}"
    echo -e "${CYAN}│${YELLOW}  3. Before pkg install/removal${CYAN}│${GREEN} 10. Clean state              ${CYAN}│${RESET}"
    echo -e "${CYAN}│${YELLOW}  4. Before downgrade          ${CYAN}│${GREEN} 11. Weekly snapshot          ${CYAN}│${RESET}"
    echo -e "${CYAN}│${YELLOW}  5. Before config change      ${CYAN}│${GREEN} 12. Monthly snapshot         ${CYAN}│${RESET}"
    echo -e "${CYAN}│${YELLOW}  6. Before migration          ${CYAN}│${GREEN} 13. After update verified    ${CYAN}│${RESET}"
    echo -e "${CYAN}│${YELLOW}  7. Security update           ${CYAN}│${GREEN} 14. Before testing           ${CYAN}│${RESET}"
    echo -e "${CYAN}└───────────────────────────────┴──────────────────────────────┘${RESET}"
    echo -e "     ${CYAN}0.${RESET}  Custom — type your own reason\n"
    printf "Choice [0-14] : "
    read -r reason_choice

    local desc smart_default="s"
    case "$reason_choice" in
        1)  desc="Before system update (zypper dup)";  smart_default="i" ;;
        2)  desc="Before kernel change";               smart_default="i" ;;
        3)  desc="Before pkg install/removal";         smart_default="i" ;;
        4)  desc="Before downgrade";                   smart_default="i" ;;
        5)  desc="Before config change";               smart_default="i" ;;
        6)  desc="Before migration";                   smart_default="i" ;;
        7)  desc="Security update";                    smart_default="i" ;;
        8)  desc="Routine checkpoint";                 smart_default="s" ;;
        9)  desc="After successful test";              smart_default="s" ;;
        10) desc="Clean state";                        smart_default="s" ;;
        11) desc="Weekly snapshot";                    smart_default="s" ;;
        12) desc="Monthly snapshot";                   smart_default="s" ;;
        13) desc="After update verified";              smart_default="s" ;;
        14) desc="Before testing";                     smart_default="s" ;;
        *)
            printf "\n${BOLD}Reason${RESET} : "
            read -r desc
            if [[ -z "$desc" ]]; then
                echo -e "${RED}Error: reason is required${RESET}"
                return 1
            fi
            if echo "$desc" | grep -qiE 'update|upgrade|zypper|before|avant|downgrade|security|kernel|migration'; then
                smart_default="i"
            fi
            ;;
    esac

    # 2. Config selection (only if home config exists)
    local configs config="root"
    configs=$(sudo snapper list-configs 2>/dev/null | awk 'NR>2 {print $1}' | tr '\n' ' ')
    if echo "$configs" | grep -q "home"; then
        echo -e "\n${BOLD}Config:${RESET}"
        echo -e "  ${CYAN}(r)${RESET} root"
        echo -e "  ${CYAN}(h)${RESET} home"
        echo -e "  ${CYAN}(b)${RESET} both"
        printf "Choice [rhb] (default: r) : "
        read -r cfg_choice
        if [[ "$cfg_choice" =~ ^[hH]$ ]]; then
            config="home"
        elif [[ "$cfg_choice" =~ ^[bB]$ ]]; then
            config="both"
        else
            config="root"
        fi
    fi

    # 3. Disk space check (warn if > 85%)
    local usage
    usage=$(df / | awk 'NR==2 {print $5}' | tr -d '%')
    if [[ "$usage" -gt 85 ]]; then
        echo -e "\n${YELLOW}⚠ Warning: disk usage is ${usage}% — creating a snapshot may worsen space pressure${RESET}"
        printf "Continue anyway? [y/N] : "
        read -r space_confirm
        if [[ ! "$space_confirm" =~ ^[yYoO]$ ]]; then
            echo -e "${YELLOW}Cancelled.${RESET}"
            return 0
        fi
    fi

    # 4. Context: snapshot count + last snapshot per config
    local -a target_configs
    if [[ "$config" == "both" ]]; then
        target_configs=(root home)
    else
        target_configs=($config)
    fi

    echo -e "\n${BOLD}Current state:${RESET}"
    for cfg in "${target_configs[@]}"; do
        local count last_line last_id last_date last_desc_ctx last_type last_userdata last_status last_status_color
        count=$(sudo snapper -c "$cfg" list 2>/dev/null | tail -n +3 | grep -c "│" || echo "0")
        last_line=$(sudo snapper -c "$cfg" list 2>/dev/null | grep "│" | tail -1)
        last_id=$(echo "$last_line"       | awk -F'│' '{gsub(/ /,"",$1); print $1}')
        last_type=$(echo "$last_line"     | awk -F'│' '{gsub(/^ +| +$/,"",$2); print $2}')
        last_date=$(echo "$last_line"     | awk -F'│' '{gsub(/^ +| +$/,"",$4); print $4}')
        last_desc_ctx=$(echo "$last_line" | awk -F'│' '{gsub(/^ +| +$/,"",$8); print $8}')
        last_userdata=$(echo "$last_line" | awk -F'│' '{gsub(/^ +| +$/,"",$9); print $9}')
        if echo "$last_userdata" | grep -q "important=yes"; then
            last_status="important"
            last_status_color="$YELLOW"
        else
            last_status="standard"
            last_status_color="$GREEN"
        fi
        echo -e "  ${CYAN}${cfg}${RESET} — ${count} snapshot(s) — last: #${last_id} \"${last_desc_ctx}\" [${last_type}, ${last_status_color}${last_status}${RESET}] (${last_date})"
    done

    # 5. Type selection (smart default based on scenario or keywords)
    echo -e "\n${BOLD}Type:${RESET}"
    echo -e "  ${GREEN}(s)${RESET} Standard  — automatic timeline cleanup"
    echo -e "  ${YELLOW}(i)${RESET} Important — protected from automatic cleanup"
    if [[ "$smart_default" == "i" ]]; then
        echo -e "  ${CYAN}→ Suggested: important (based on selected scenario)${RESET}"
        printf "Choice [si] (default: i) : "
    else
        printf "Choice [si] (default: s) : "
    fi
    read -r type_choice

    local userdata="" type_label type_color
    if [[ "$type_choice" =~ ^[iI]$ ]] || [[ -z "$type_choice" && "$smart_default" == "i" ]]; then
        userdata="important=yes"
        type_label="important"
        type_color="$YELLOW"
    else
        type_label="standard"
        type_color="$GREEN"
    fi

    # 6. Colored confirmation summary
    echo -e "\n${BOLD}Summary:${RESET}"
    echo -e "  Config  : ${CYAN}${config}${RESET}"
    echo -e "  Type    : ${type_color}${type_label}${RESET}"
    echo -e "  Reason  : ${BOLD}${desc}${RESET}"
    printf "\nConfirm? [y/N] : "
    read -r confirm
    if [[ ! "$confirm" =~ ^[yYoO]$ ]]; then
        echo -e "${YELLOW}Cancelled.${RESET}"
        return 0
    fi

    # 7. Create snapshot(s) + feedback with prev and new IDs
    echo ""
    for cfg in "${target_configs[@]}"; do
        local prev_id new_id
        prev_id=$(sudo snapper -c "$cfg" list 2>/dev/null | grep "│" | tail -1 | awk -F'│' '{gsub(/ /,"",$1); print $1}')

        local args=(-c "$cfg" create --description "$desc" --cleanup-algorithm timeline)
        [[ -n "$userdata" ]] && args+=(--userdata "$userdata")
        sudo snapper "${args[@]}"

        new_id=$(sudo snapper -c "$cfg" list 2>/dev/null | grep "│" | tail -1 | awk -F'│' '{gsub(/ /,"",$1); print $1}')
        echo -e "${BOLD}${GREEN}✓ Snapshot #${new_id} created${RESET} [${CYAN}${cfg}${RESET}] — ${type_color}${type_label}${RESET} — \"${desc}\" ${RESET}(previous: #${prev_id})"
    done
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
