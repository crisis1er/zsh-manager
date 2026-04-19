# Changelog

All notable changes to this plugin are documented here.

---

## [2.2] — 2026-04-19

### Changed
- Btrfs functions extracted to dedicated plugins (hub-and-plugin architecture)
  - `btrfs-scrub` + aliases → zsh-btrfs-scrub
  - `btrfs-balance` + `btrfs-balance-threshold` + aliases → zsh-btrfs-balance
  - `btrfs-health` + `btrfs-snap-size` → zsh-btrfs-health
- Replaced btrfs function bodies with stubs pointing to dedicated plugins
- snap-help updated to reference dedicated plugins
- Repo renamed: zsh-snap-man → zsh-manager (GitHub + local)

---

## [2.1] — 2026-04-19

### Changed
- Renamed plugin directory and entry point: `btrfs-snapper` → `snap-man` (avoids collision with system `snap` command)
- Renamed unified entry point: `snap()` → `snap-man()`

### Added
- `snap-help` — display all available commands with descriptions
- `man-s` alias — quick access to `snap-help`
- Short aliases for all commands:
  - `snap-m` → `snap-man` (unified manager)
  - `snap-l` → `snap-list`
  - `snap-n` → `snap-new`
  - `snap-r` → `snap-rollback`
  - `snap-d` → `snap-del`
  - `snap-c` → `snap-compare`
- Standard banner (CYAN border, version + date, SafeITExperts)

---

## [2.0] — 2026-04-12

### Changed
- Translated all comments and output messages to English
- Replaced `snap-list`, `snap-new`, `snap-rollback` full function bodies with lightweight stubs
  — these features are now provided by independent plugins (`zsh-snap-list`, `zsh-snap-new`, `zsh-snap-rollback`)
  — stubs display a clear install message if the plugin is not loaded

### Added
- `snap()` — unified entry point with interactive menu: list / create / rollback
  — delegates to the three independent plugins
  — colored display with ANSI box border

### Removed
- Embedded `snap-list` implementation (moved to `zsh-snap-list` plugin)
- Embedded `snap-new` implementation (moved to `zsh-snap-new` plugin)
- Embedded `snap-rollback` implementation (moved to `zsh-snap-rollback` plugin)

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
