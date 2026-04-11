# Changelog

All notable changes to this plugin are documented here.

---

## [1.0] — 2026-04-06

### Added
- Initial release — Oh My Zsh plugin for btrfs and snapper on openSUSE Tumbleweed
- `snap-list` — colorized snapshot list (green = current, yellow = important) with summary
- `snap-new` — interactive guided snapshot creation (reason, config, type, confirmation, colored feedback)
- `snap-del <id>` — delete snapshot with usage hint if no argument
- `snap-rollback <id>` — rollback with mandatory confirmation prompt
- `snap-compare <id1> <id2>` — diff files changed between two snapshots
- `snap-important` — filter and display only important snapshots
- `snap-manual` — filter and display only manually created snapshots
- `snap-list-root` / `snap-list-home` — per-config snapshot listing
- `snap-create-root` / `snap-create-home` — per-config snapshot creation
- `snap-cleanup` / `snap-cleanup-all` — snapper cleanup aliases
- `rollback-last` — fast rollback to last snapshot (expert use, no confirmation)
- `btrfs-scrub` — start scrub and display live status
- `btrfs-scrub-status/cancel/resume` — scrub control aliases
- `btrfs-balance` — balance with configurable dusage/musage thresholds
- `btrfs-balance-threshold` — conditional balance based on actual disk usage
- `btrfs-balance-status/pause/resume/cancel` — balance control aliases
- `btrfs-snap-size` — display real disk space used by snapshots
- `btrfs-health` — full btrfs health report (usage, device stats, scrub, snapshots)
- `btrfs-df` / `btrfs-usage` / `btrfs-show` / `btrfs-subvols` / `btrfs-stats` — filesystem aliases
