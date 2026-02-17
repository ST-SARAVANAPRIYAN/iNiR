# Changelog

All notable changes to iNiR will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.10.2] - 2026-02-17

### Added
- **Terminal theming for btop, lazygit, yazi**: Auto-generate Material You color themes for btop++ (system monitor), lazygit (git TUI), and yazi (file manager) — colors sync with wallpaper theme just like terminals
- **btop theme**: Full color mapping for graphs, boxes, meters, process list; auto-sets `color_theme = "ii-auto"` in btop.conf
- **lazygit theme**: Merges `gui.theme` section into config.yml safely (borders, selection, commit colors, staged/unstaged indicators)
- **yazi flavor**: Generates `ii-auto.yazi` flavor with modern `[mgr]`/`[mode]` format — manager, status bar, input, which-key, filetype colors all themed
- **UI toggles**: Settings → Terminal Colors now shows btop, lazygit, yazi toggles with auto-detect (10 tools total)
- **Waffle per-monitor wallpaper management**: Full UI in Waffle settings for per-monitor wallpaper selection
- **Waffle Win11-style wallpaper UI**: Hero section with monitor frame preview + thumbnail grid + overlay action buttons
- **Angel global style**: New 5th global style (neo-brutalism glass) across all shell surfaces

### Changed
- **Arch install: darkly → darkly-bin**: Pre-built binary package replaces source build — saves ~5 minutes on fresh install, same functionality
- **Waffle settings sidebar collapsed mode**: Centered icons (20px), tooltips on hover, accent-colored header icon
- **Waffle widgets panel**: Dynamic weather icon (day/night), thicker progress bars (6px), card-style quick action buttons in Grid layout
- **Waffle notifications**: GroupExpandButton with chevron icon and accent-colored text (Win11-like)
- **Material QuickConfig**: Wallpaper grid max height reduced 400→280px for less visual bulk
- **Terminal color detection**: Auto-detect now scans all 10 tools (was 7)

### Fixed
- **Config safety audit (34 fixes)**: 19 unsafe writes in GeneralConfig.qml → `setNestedValue()`; 15 unsafe reads in SidebarLeft → optional chaining + defaults
- **Waffle config safety**: WModulesPage unsafe write, OSDValue unsafe read
- **BarPopup warning**: `Keys.onPressed` on non-Item PopupWindow → `Shortcut` component
- **ActionCenterContent binding loop**: opacity binding loop → `visible` property
- **WSettingsRow missing animation**: Added `highlightAnim` SequentialAnimation for search focus
- **QuickConfig "Use current folder"**: Safe config access with optional chaining
- **Fresh install defaults**: pinnedApps, polkit, GTK-first defaults for non-KDE users
- **Install deps**: dolphin→nautilus, added missing dependencies
- **Setup install: 0-byte wallpaper recovery**: Overwrite empty/corrupt wallpapers from failed installs (`-s` check) — fixes matugen crash on re-install
- **Setup install: version.json created on install**: ShellUpdates service now works from first boot (repo path, version, commit tracked)
- **Setup install: polkit agent auto-detection**: Detects KDE→GNOME→MATE→LX→LXQt polkit agent instead of hardcoding mate
- **Setup install: Qt theme detection**: `QT_QPA_PLATFORMTHEME` set to `kde` or `qt6ct` based on Plasma presence
- **Setup install: shell env vars**: `ILLOGICAL_IMPULSE_VIRTUAL_ENV` written to bash/fish/zsh profiles (not just niri config.kdl)
- **Setup install: conflict auto-disable**: Dunst and other conflicting services auto-disabled in non-interactive mode
- **Setup install: dynamic wallpaper selection**: Default wallpaper picks first available file instead of hardcoding a filename
- **Sound effects enabled by default**: New installs start with notification sounds on (user can disable in welcome wizard or settings)

## [2.10.1] - 2026-02-13

### Added
- **Desktop right-click context menu**: Right-click on the desktop background opens a context menu with Mission Center, Overview/Task View, Settings, Wallpaper Selector, Terminal, Media Controls, Lock Screen, and Power Menu
- **Bar right-click context menu (ii family)**: Right-click on the horizontal or vertical bar opens a context menu with Mission Center and Settings
- **DesktopShellContextMenu component**: Reusable context menu widget for desktop backgrounds, respects all three global styles (Material, Aurora, iNiR)

### Changed
- **Bar context menu positioning**: Vertical bar popup opens toward screen center (right when bar is left, left when bar is right) following the dock pattern; horizontal bar popup opens above when bar is at bottom, below when at top
- **Desktop context menu close behavior**: Left-click on desktop closes the menu; right-click repositions it — avoids layer-shell backdrop conflict on Niri

## [2.10.0] - 2026-02-13

### Added
- **Multi-monitor wallpaper support**: Per-monitor wallpaper and backdrop paths via WallpaperListener service
- **Video first-frame system**: Automatic ffmpeg extraction and caching of first-frame JPGs for video wallpapers
- **Per-monitor aurora/glass**: Bar, dock, and sidebars use per-screen wallpaper for blur and color quantization
- **Wallpaper selector multi-monitor targeting**: Auto-detects focused monitor, opens on target screen, per-monitor selection
- **Per-monitor backdrop paths**: Each monitor can have its own backdrop wallpaper independent of global setting
- **Derive theme colors from backdrop**: New toggle in settings — all color generation sources (matugen, ColorQuantizer, aurora) switch to backdrop wallpaper when enabled
- **Card right-click swap**: Right-click on the front card toggles between main wallpaper and backdrop views
- **Backdrop card focus borders**: Selection border overlay when backdrop card is in front and selected
- **DockPreview toplevel reactivity**: Auto-close preview when app exits, update on toplevel changes
- **Per-monitor random wallpapers**: Random wallpaper scripts (konachan, osu) support focused monitor targeting

### Changed
- **Card clipping**: Parent-level `layer.enabled + OpacityMask` replaces per-image masking — all children (gradients, labels, badges) now properly clip to rounded corners
- **Card scaling quality**: `layer.smooth` on scaled cards for sharper text and badges when zoomed out
- **Video/GIF display**: Always load AnimatedImage for GIFs (frozen when animation disabled); replaced QtMultimedia Video with first-frame Image in previews
- **Color pipeline**: ColorQuantizer and effectiveWallpaperUrl return image-safe sources for videos (first-frame cache → config thumbnail → trigger generation)
- **switchwall.sh**: Per-monitor wallpaper changes skip global color regeneration; `--noswitch` reads current wallpaper from config
- **CryptoWidget**: Cache staleness check — only refresh if older than refreshInterval (default 300s)
- **WaffleConfig**: Use `Config.setNestedValue()` instead of direct property mutation

### Fixed
- **Black peaks on cards**: Gradient and label overlays no longer escape rounded corners (`clip:true` only clips rectangular)
- **Aurora colors for video wallpapers**: ColorQuantizer receives first-frame images instead of undecoded video URLs
- **Backdrop changes all monitors**: Per-monitor backdrop selection now only affects the selected monitor
- **White line above wallpaper path**: Removed hardcoded separator — `Layout.topMargin` provides sufficient spacing
- **Derive theme colors noop**: Toggle now wires through to Appearance.qml ColorQuantizer, Wallpapers.effectiveWallpaperPath, and switchwall.sh matugen source

## [2.9.1] - 2026-02-11

### Added
- **Weather location debouncing**: Wait 1.5 seconds after user finishes typing before triggering geocoding to reduce API calls
- **Weather geocoding improvements**: Smarter display name formatting (city, country) for manual location entries
- **Cliphist lazy image decode**: Only decode images when they become visible, reducing process spam
- **YtMusic dependency reporting**: Show exactly which dependencies are missing and how to install them

### Changed
- **GitHub templates**: Streamlined issue and PR templates for clarity and conciseness
- **Package dependencies**: Added missing required commands to doctor.sh and PKGBUILDs (python, xdg-utils, curl, git, swayidle, fuzzel, pacman-contrib, ddcutil, translate-shell)
- **PACKAGES.md documentation**: Synchronized with actual package requirements

### Fixed
- **Video wallpaper blur**: Blur effect now works correctly with video wallpapers (removed video guard clause)
- **Overlay pinned widgets**: Pinned widgets now display correctly when the overlay is closed
- **Clipboard self-trigger**: Prevented clipboard from refreshing when copying its own entries
- **YtMusic mpv-mpris**: Made mpv-mpris plugin optional so playback works without it
- **YtMusic cookie path**: Fixed path for cookie file used by mpv
- **Weather re-fetch**: Prevent duplicate location resolution on shell restart with manual coordinates

## [2.9.0] - 2026-02-11

### Added
- **Shell update overlay**: New layer-shell panel with commit log, changelog preview, and local modifications detection
- **Shell update details**: Click bar indicator to open detailed overlay instead of direct update
- **Weather manual location**: City name input, manual lat/lon coordinates, and GPS support via geoclue
- **Weather geocoding**: Forward geocoding (city → coords) and reverse geocoding (coords → display name) via Nominatim
- **Waffle themes redesign**: Theme cards with live color preview circles, quick-apply, inline rename, import/export
- **WWaffleStylePage options**: Start menu scale slider, clock format options, bar sizing controls (height, icon size, corner radius), desktop peek section
- **Waffle pages icon audit**: Replaced generic icons with descriptive FluentIcons across all settings pages
- **Ko-fi funding**: Added ko_fi to FUNDING.yml

### Changed
- **Waffle settings isolation**: Waffle family always opens its own Win11-style settings window, simplified IPC toggle logic
- **Win11 visual polish**: Redesigned waffle settings widgets with shadows, compact sizing, animated transitions using Looks.transition tokens
- **Weather priority**: Manual coords > manual city > GPS > IP auto-detect
- **ShellUpdates service**: Added overlay state management, manifest parsing, IPC handlers (toggle/open/close/check/update/dismiss)

### Fixed
- **Config schema sync**: Added 6 missing altSwitcher properties, enableAnimation for WaffleBackground, noVisualUi and taskView.closeOnSelect defaults
- **Settings bugs**: Fixed BarConfig layout property name, WaffleConfig bindings and spacing
- **YtMusic persistence**: Connection state and resolvedBrowserArg now persist across restarts
- **YtMusic cookies**: Always use --cookies-from-browser instead of intermediate cookie files, resolve Firefox fork profile paths
- **YtMusic debugging**: Added stderr capture and logging for mpv, converted shell commands to proper array-based Process commands
- **Waffle start menu overflow**: Added clip, Flickable wrapper, min/max height constraints, reduced recommended items from 6 to 4

## [2.8.2] - 2026-02-09

### Added
- **Dock screen filtering**: `screenList` config option for per-monitor dock control, matching bar behavior (thanks @ainia for the reminder)

### Fixed
- **Dock animations**: Resolved flickering during app launch and drag operations (PR #40 by @Legnatbird)

## [2.8.1] - 2026-02-08

### Added
- **Settings search**: Granular per-option search index with spotlight scroll-to navigation
- **Terminal detection**: Auto-detect installed terminals in color config section on first expand
- **Crypto cache**: Persist crypto widget prices and sparkline data across shell restarts
- **Notification options**: `ignoreAppTimeout` and `scaleOnHover` config properties

### Changed
- **Bar center layout**: Both center groups now share effective width so workspaces stay perfectly centered regardless of active utility button count
- **Screen cast toggle (PR #29)**: Simplified to always-interactive toggle with configurable output; removed monitor count detection overhead

### Fixed
- **Media player duplication**: Bottom overlay now uses `displayPlayers` with title/position dedup, matching bar popup behavior
- **Notification popup animations**: Differentiated popup vs sidebar behavior — popups use instant height changes to avoid Wayland resize stair-stepping, with height buffer and clip to prevent content overflow
- **Hardcoded animations**: Replaced raw `NumberAnimation`/`ColorAnimation` with `Appearance.animation` and `Looks.transition` design tokens across TimerIndicator, KeyboardKey, BarMediaPlayerItem, ThemePresetCard, TilingOverlay, and WidgetsContent
- **Screen cast settings**: Added null safety, `setNestedValue` for output field, synced defaults with Config.qml schema
- **Shell updates**: Prevented double repository search fallback when version.json exists but lacks `repo_path`

## [2.8.0] - 2026-02-04

### Added
- **Screen cast toggle**: Bar utility button for Niri screen casting with configurable output (PR #29 by @levpr1c)
- **System sounds volume control**: Configurable volume for timer, pomodoro, and battery notification sounds

### Changed
- **Video wallpapers**: Replaced mpvpaper with Qt Multimedia for native video wallpaper support

### Fixed
- **Terminal color theming**: Auto-fix for Alacritty v0.13+ import order requirement - colors now update correctly with wallpaper changes (Issue #30)
- **Package installation**: Replaced non-existent `matugen-bin` AUR package with `matugen` from official Arch repos (Issue #32)
- **Waffle background**: Added missing optional chaining in config access to prevent startup errors

## [2.7.0] - 2026-01-21

### Added
- **Bar module toggles**: Individual enable/disable options for bar modules (resources, media, workspaces, clock, utility buttons, battery, sidebar buttons)
- **Region search**: Google Lens action via IPC (`region.googleLens`)

### Changed
- **Media player pipeline**: Centralized filtering/deduping via `MprisController.displayPlayers` for consistent behavior across widgets
- **Cava visualizer**: Debounced process activation to avoid rapid stop/start loops

### Fixed
- **Shell performance**: Reduced stutter by rebuilding MPRIS player lists imperatively instead of hot bindings
- **Bar stability**: Null-safe config access for bar components to prevent startup `ReferenceError`
- **Darkly theme generation**: Adaptive clamping to prevent icons/colors from collapsing to pure black/white

## [2.6.0] - 2026-01-11

### Added
- **User modification detection**: Setup now detects user-modified files and preserves them during updates
- **Themes UI favorites**: Star your favorite color themes for quick access in settings
- **Quick Access section**: Combined favorites + recently used themes in compact grid
- **Temperature sensor support**: Extended hwmon detection for older hardware (k10temp, coretemp, etc.)
- **Control Panel**: New unified control panel with modular sections
- **Tiling Overlay**: Visual overlay for tiling operations
- **Tools tab**: New tools section in settings
- **GIF wallpaper support**: Native animated GIF wallpapers with performance optimizations
