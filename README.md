[![Visiteurs](https://visitor-badge.laobi.icu/badge?page_id=crisis1er.zsh-btrfs-snapper)](https://github.com/crisis1er/zsh-btrfs-snapper)
![Platform](https://img.shields.io/badge/platform-openSUSE%20Tumbleweed-73BA25)
![Shell](https://img.shields.io/badge/shell-zsh%205.9%2B-blue)
![OMZ](https://img.shields.io/badge/Oh%20My%20Zsh-compatible-red)
![License](https://img.shields.io/badge/license-MIT-green)
![Version](https://img.shields.io/badge/version-v1.0-orange)

# zsh-btrfs-snapper

Oh My Zsh plugin for **btrfs** filesystem management and **snapper** snapshot control on openSUSE Tumbleweed — enriched commands, safety guards, and filtered views not available in native tools.

Deployed and validated on a live openSUSE Tumbleweed system.

---

## Architecture

<sub>⚠️ If the diagram is not visible, refresh the page — Mermaid rendering may take a moment.</sub>

```mermaid
flowchart TD
    classDef plugin  fill:#1e3a5f,stroke:#93c5fd,stroke-width:2px,color:#ffffff
    classDef snap    fill:#14532d,stroke:#86efac,stroke-width:2px,color:#ffffff
    classDef btrfs   fill:#78350f,stroke:#fcd34d,stroke-width:2px,color:#ffffff
    classDef native  fill:#1f2937,stroke:#6b7280,stroke-width:2px,color:#9ca3af
    classDef safety  fill:#7f1d1d,stroke:#fca5a5,stroke-width:2px,color:#ffffff

    PLUGIN[zsh-btrfs-snapper — Oh My Zsh plugin]:::plugin

    PLUGIN --> SNAPPER
    PLUGIN --> BTRFS

    subgraph SNAPPER[" Snapshot management — snapper "]
        SL[snap-list\ncolorized + summary]:::snap
        SN[snap-new\nauto cleanup-algorithm]:::snap
        SR[snap-rollback\nmandatory confirmation]:::safety
        SC[snap-compare\ndiff between snapshots]:::snap
        SF[snap-important / snap-manual\nfiltered views]:::snap
    end

    subgraph BTRFS[" Filesystem maintenance — btrfs-progs "]
        BS[btrfs-scrub\nstart + live status]:::btrfs
        BB[btrfs-balance\nconfigurable thresholds]:::btrfs
        BT[btrfs-balance-threshold\nconditional balance]:::btrfs
        BH[btrfs-health\naggregated report]:::btrfs
        BZ[btrfs-snap-size\nqgroup disk usage]:::btrfs
    end
```

---

## Requirements

- openSUSE Tumbleweed
- zsh 5.9+
- [Oh My Zsh](https://ohmyz.sh/)
- `btrfs-progs` — `sudo zypper install btrfs-progs`
- `snapper` — `sudo zypper install snapper`

---

## Installation

```zsh
git clone https://github.com/crisis1er/zsh-btrfs-snapper \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/btrfs-snapper
```

Add `btrfs-snapper` to the plugins list in `~/.zshrc`:

```zsh
plugins=(... btrfs-snapper)
```

Reload:

```zsh
source ~/.zshrc
```

---

## Snapshot functions

| Command | Description |
|---|---|
| `snap-list` | Colorized snapshot list — current in green, important in yellow — with summary |
| `snap-new "description"` | Create snapshot with automatic `timeline` cleanup algorithm |
| `snap-del <id>` | Delete snapshot — displays list if no argument provided |
| `snap-rollback <id>` | Rollback with mandatory confirmation — displays list if no argument |
| `snap-compare <id1> <id2>` | Show files changed between two snapshots |
| `snap-important` | Display only `important=yes` snapshots |
| `snap-manual` | Display only manually created snapshots (excludes zypper/timeline) |
| `rollback-last` | Fast rollback to last snapshot — no confirmation, expert use |

### Multi-config aliases

| Command | Description |
|---|---|
| `snap-list-root` | List snapshots for config `root` |
| `snap-list-home` | List snapshots for config `home` |
| `snap-create-root "desc"` | Create snapshot in config `root` |
| `snap-create-home "desc"` | Create snapshot in config `home` |
| `snap-cleanup` | Run snapper cleanup (number algorithm) |
| `snap-cleanup-all` | Run snapper cleanup all |

---

## Btrfs functions

| Command | Description |
|---|---|
| `btrfs-scrub [mountpoint]` | Start scrub and display live status (default: `/`) |
| `btrfs-balance [dusage] [musage]` | Balance with configurable thresholds (default: 50%) |
| `btrfs-balance-threshold [%]` | Conditional balance — only runs if disk usage exceeds threshold (default: 75%) |
| `btrfs-snap-size` | Real disk space used by snapshots via btrfs qgroup |
| `btrfs-health` | Full report: filesystem usage + device errors + scrub status + snapshot summary |

### Scrub aliases

| Command | Description |
|---|---|
| `btrfs-scrub-status` | Show current scrub status |
| `btrfs-scrub-cancel` | Cancel running scrub |
| `btrfs-scrub-resume` | Resume paused scrub |

### Balance aliases

| Command | Description |
|---|---|
| `btrfs-balance-status` | Show current balance status |
| `btrfs-balance-pause` | Pause running balance |
| `btrfs-balance-resume` | Resume paused balance |
| `btrfs-balance-cancel` | Cancel running balance |

### Filesystem aliases

| Command | Description |
|---|---|
| `btrfs-df` | `btrfs filesystem df /` |
| `btrfs-usage` | `btrfs filesystem usage /` |
| `btrfs-show` | `btrfs filesystem show` |
| `btrfs-subvols` | List all subvolumes |
| `btrfs-stats` | Device error statistics |

---

## Design decisions

- **`btrfs-defrag` is intentionally excluded** — defragmentation breaks Copy-on-Write on btrfs and increases disk usage
- `snap-rollback` always requires confirmation — accidental rollbacks are irreversible
- `function name { }` syntax used throughout — prevents zsh alias/function conflicts on shell reload
- Paths use `/.snapshots/` — correct location on openSUSE (not `/mnt/.snapshots/`)
