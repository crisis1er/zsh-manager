# ============================================================
# btrfs-snapper — Oh My Zsh plugin for openSUSE Tumbleweed
# Enhanced btrfs and snapper management
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
# Usage : snap
function snap {
    local CYAN="\033[36m" BOLD="\033[1m" RESET="\033[0m" RED="\033[31m"
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║${RESET}${BOLD}              Snap Manager — SafeITExperts                     ${RESET}${CYAN}║${RESET}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "  ${CYAN}(1)${RESET} snap-list     — list snapshots"
    echo -e "  ${CYAN}(2)${RESET} snap-new      — create a snapshot"
    echo -e "  ${CYAN}(3)${RESET} snap-rollback — rollback to a snapshot"
    printf "\nChoice [1/2/3] : "
    read -r choice
    case "$choice" in
        1) snap-list ;;
        2) snap-new ;;
        3) snap-rollback ;;
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
