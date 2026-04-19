# ============================================================
# snap-man — Oh My Zsh plugin for openSUSE Tumbleweed
# Snap Manager + Enhanced btrfs and snapper management
# Version: 2.1 — 2026-04-19
# ============================================================

# ------------------------------------------------------------
# Aliases — Useful shortcuts (no native duplicates)
# ------------------------------------------------------------

# Multi-config snapper shortcuts (avoids memorizing -c root/-c home)
alias snap-list-root='sudo snapper -c root list'
alias snap-create-root='sudo snapper -c root create --description'
alias snap-list-home='sudo snapper -c home list'
alias snap-create-home='sudo snapper -c home create --description'

# Cleanup
alias snap-cleanup='sudo snapper cleanup number'
alias snap-cleanup-all='sudo snapper cleanup all'

# Quick rollback (no confirmation — expert use)
alias rollback-last='sudo snapper rollback'

# Btrfs — monitor ongoing scrub/balance operations
alias btrfs-scrub-status='sudo btrfs scrub status /'
alias btrfs-scrub-cancel='sudo btrfs scrub cancel /'
alias btrfs-scrub-resume='sudo btrfs scrub resume /'
alias btrfs-balance-status='sudo btrfs balance status /'
alias btrfs-balance-pause='sudo btrfs balance pause /'
alias btrfs-balance-resume='sudo btrfs balance resume /'
alias btrfs-balance-cancel='sudo btrfs balance cancel /'

# ------------------------------------------------------------
# Enhanced functions — Snapper
# ------------------------------------------------------------

# Remove any residual aliases that would shadow the functions
unalias snap-list snap-new snap-del snap-rollback snap-compare 2>/dev/null
unalias btrfs-scrub btrfs-balance btrfs-balance-threshold btrfs-snap-size btrfs-health 2>/dev/null

# snap-list, snap-new, snap-rollback are now independent plugins.
# These stubs ensure backward compatibility if the plugins are not loaded.
function snap-list {
    echo "zsh-snap-list plugin not loaded. Install it or add snap-list to plugins=() in ~/.zshrc"
}
function snap-new {
    echo "zsh-snap-new plugin not loaded. Install it or add snap-new to plugins=() in ~/.zshrc"
}
function snap-rollback {
    echo "zsh-snap-rollback plugin not loaded. Install it or add snap-rollback to plugins=() in ~/.zshrc"
}

# Delete one or more snapshots — shows list if no argument given
# Usage : snap-del 42  or  snap-del 40-45
function snap-del {
    if [[ -z "$1" ]]; then
        echo "Usage: snap-del <id>  or  snap-del <id1>-<id2>"
        snap-list
        return 1
    fi
    sudo snapper delete "$1"
}

# ── Snap manager — unified entry point ───────────────────────────────────────
# Usage : snap-man
function snap-man {
    local CYAN="\033[36m" BOLD="\033[1m" RESET="\033[0m" RED="\033[31m"
    local YELLOW="\033[33m" GREEN="\033[32m"

    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║${RESET}${BOLD}              Snap Manager — SafeITExperts                     ${RESET}${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET}              Btrfs Snapshot Manager for openSUSE Tumbleweed  ${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET}              Version v2.1 — 2026-04-19                       ${CYAN}║${RESET}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${RESET}"
    echo -e "${CYAN}║${RESET}  Manage your system snapshots safely from one place.         ${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET}                                                              ${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET}  ${YELLOW}→${RESET} ${BOLD}List${RESET}     — view all snapshots with colors and filters   ${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET}  ${GREEN}→${RESET} ${BOLD}New${RESET}      — create a snapshot before any system change    ${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET}  ${RED}→${RESET} ${BOLD}Rollback${RESET} — restore your system to a previous snapshot    ${CYAN}║${RESET}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "  ${YELLOW}(1)${RESET} snap-list     ${CYAN}[snap-l]${RESET} — list and filter snapshots"
    echo -e "  ${GREEN}(2)${RESET} snap-new      ${CYAN}[snap-n]${RESET} — guided snapshot creation"
    echo -e "  ${RED}(3)${RESET} snap-rollback ${CYAN}[snap-r]${RESET} — rollback to a chosen snapshot"
    echo -e "  ${CYAN}(h)${RESET} snap-help     ${CYAN}[snap-h]${RESET} — show all available commands"
    echo -e "  ${CYAN}    snap-man      [man-s]${RESET}     — shortcut to this manager"
    echo -e "  ${CYAN}(q)${RESET} quit"
    printf "\nChoice [1/2/3/h/q] : "
    read -r choice < /dev/tty
    case "$choice" in
        1) snap-list ;;
        2) snap-new ;;
        3) snap-rollback ;;
        h|H) snap-help ;;
        q|Q) echo -e "${YELLOW}Cancelled.${RESET}" ; return 0 ;;
        *) echo -e "${RED}Invalid choice.${RESET}" ; return 1 ;;
    esac
}

# Compare modified files between two snapshots
# Usage : snap-compare 41 42
function snap-compare {
    if [[ -z "$2" ]]; then
        echo "Usage: snap-compare <id1> <id2>"
        return 1
    fi
    sudo snapper diff "$1".."$2"
}

# Show only important snapshots
function snap-important {
    sudo snapper list | awk 'NR<=2 || /important=yes/'
}

# Show only manual snapshots (not zypper, not timeline)
function snap-manual {
    sudo snapper list | awk 'NR<=2 || ($0 !~ /zypp/ && $0 !~ /timeline/ && NR>2)'
}

# ------------------------------------------------------------
# Enhanced functions — Btrfs maintenance
# ------------------------------------------------------------

# Start a scrub and follow its status
# Usage : btrfs-scrub  or  btrfs-scrub /mnt/data
function btrfs-scrub {
    local mount="${1:-/}"
    echo "Starting scrub on $mount..."
    sudo btrfs scrub start "$mount"
    sleep 2
    sudo btrfs scrub status "$mount"
}

# Balance with configurable thresholds (default: 50%)
# Usage : btrfs-balance  or  btrfs-balance 70 70
function btrfs-balance {
    local dusage="${1:-50}"
    local musage="${2:-50}"
    echo "Btrfs balance: dusage=${dusage}% musage=${musage}%"
    sudo btrfs balance start -dusage="$dusage" -musage="$musage" /
}

# Conditional balance based on actual disk usage
# Usage : btrfs-balance-threshold  or  btrfs-balance-threshold 70
function btrfs-balance-threshold {
    local threshold="${1:-75}"
    local usage
    usage=$(df / | awk 'NR==2 {print $5}' | tr -d '%')
    if [[ "$usage" -gt "$threshold" ]]; then
        echo "Usage /: ${usage}% > ${threshold}% — starting balance"
        sudo btrfs balance start -dusage=5 /
    else
        echo "Usage /: ${usage}% < ${threshold}% — balance not needed"
    fi
}

# Actual disk space used by snapshots (openSUSE path: /.snapshots/)
function btrfs-snap-size {
    echo "Snapshot disk usage:"
    sudo btrfs qgroup show --sort=rfer / 2>/dev/null || \
        sudo du -sh /.snapshots/*/snapshot 2>/dev/null | sort -h
}

# Full btrfs health report
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

# ── snap-help — list all available commands ───────────────────────────────────
function snap-help {
    local CYAN="\033[36m" BOLD="\033[1m" RESET="\033[0m" YELLOW="\033[33m"
    local GREEN="\033[32m" RED="\033[31m"
    echo -e "${BOLD}Snap Manager — available commands${RESET}\n"
    echo -e "  ${CYAN}snap-man${RESET}  ${CYAN}[man-s]${RESET}     — open the unified manager menu"
    echo -e "  ${CYAN}snap-help${RESET} ${CYAN}[snap-h]${RESET} — show this help"
    echo -e "  ${YELLOW}snap-list${RESET} ${CYAN}[snap-l]${RESET} — list and filter snapshots"
    echo -e "  ${GREEN}snap-new${RESET}  ${CYAN}[snap-n]${RESET} — guided snapshot creation"
    echo -e "  ${RED}snap-rollback${RESET} ${CYAN}[snap-r]${RESET} — rollback to a chosen snapshot"
    echo -e "  ${CYAN}snap-del${RESET}  ${CYAN}[snap-d]${RESET} — delete one or more snapshots"
    echo -e "  ${CYAN}snap-compare${RESET} ${CYAN}[snap-c]${RESET} — compare two snapshots"
    echo -e "  ${CYAN}snap-important${RESET}   — list important snapshots only"
    echo -e "  ${CYAN}snap-manual${RESET}      — list manual snapshots only"
    echo ""
    echo -e "  ${CYAN}btrfs-health${RESET}              — full btrfs health report"
    echo -e "  ${CYAN}btrfs-scrub${RESET}               — start scrub and show status"
    echo -e "  ${CYAN}btrfs-balance${RESET}             — balance with configurable thresholds"
    echo -e "  ${CYAN}btrfs-balance-threshold${RESET}   — conditional balance by disk usage"
    echo -e "  ${CYAN}btrfs-snap-size${RESET}           — disk space used by snapshots"
}

# ------------------------------------------------------------
# Short aliases — fast typing, no ambiguity
# ------------------------------------------------------------
alias man-s='snap-man'
alias snap-l='snap-list'
alias snap-n='snap-new'
alias snap-r='snap-rollback'
alias snap-d='snap-del'
alias snap-c='snap-compare'
alias snap-h='snap-help'
