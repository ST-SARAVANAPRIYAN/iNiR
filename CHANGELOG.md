# Changelog

All notable changes to ii-niri will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.2.0] - 2025-12-14

### Added
- Snapshot system for time-machine style rollbacks
- `./setup rollback` command to restore previous states
- Auto git fetch and pull in update command
- Doctor now auto-starts shell if not running
- Fish shell added to core dependencies
- EasyEffects added to audio dependencies

### Changed
- Simplified setup to 4 commands: install, update, doctor, rollback
- Update now checks remote for new commits before syncing
- Update creates snapshot automatically before applying changes
- Doctor now fixes issues automatically (uv pip, version tracking, manifest)
- Removed redundant commands (install-deps, migrate, status, changelog, restore)

### Fixed
- Doctor now uses `uv pip` instead of `pip` for Python package checks
- Update now properly restarts shell after sync
- Backup directory no longer created when empty

## [2.1.0] - 2025-12-14

### Added
- New versioning system with proper version tracking
- `./setup status` command shows installed vs available version
- `./setup changelog` command to view recent changes
- Smart update detection - only syncs when there are actual changes
- Version comparison with remote repository
- Cached remote version checks (1 hour TTL)

### Changed
- Improved `./setup update` to check for changes before syncing
- Better migration system with clearer separation from installation
- Enhanced status output with pending migrations count

### Fixed
- Pomodoro timer now properly syncs with Config changes
- Volume slider maintains sync with external changes (keybinds)
- GameMode state now persists across shell restarts

## [2.0.0] - 2025-12-10

### Added
- Migration system for safe config updates
- `./setup migrate` command for interactive config migrations
- Automatic backups before any config modification
- `./setup restore` command to restore from backups
- Support for both Material (ii) and Fluent (waffle) panel families

### Changed
- `./setup update` now only syncs QML code, never touches user configs
- Migrations are now optional and interactive
- Improved first-run detection and handling

### Philosophy
- User configs are sacred - never modified without explicit consent
- Transparency - users see exactly what will change
- Reversibility - automatic backups, easy restore

## [1.0.0] - 2025-11-01

### Added
- Initial release of ii-niri
- Material Design (ii) panel family
- Windows 11 style (waffle) panel family
- System tray with smart activation
- Notifications with Do Not Disturb
- Media controls (MPRIS)
- Workspace management
- Quick settings panel
- Lockscreen
- Game mode for reduced latency
- Hot-reload for development

---

For older changes, see git history: `git log --oneline`
