<p align="center">
  <img src="docs/icon.png" width="160" alt="Gigavore icon">
</p>

<h1 align="center">Gigavore</h1>

<p align="center">
  A native macOS app that shows you what is eating your gigabytes —
  scan a folder or the whole disk and explore the usage as an interactive treemap.
</p>

## Features

- **Background scanning** of any folder or the entire disk, with live progress
  (file count, accumulated size, current path) and cancellation
- **Squarified treemap** visualization — tile size is proportional to size on disk
- **Drill-down navigation** — click a folder to open it, use the breadcrumb to jump back
- **Sidebar list** of the current folder's items sorted by size, with percentage bars
- **Right-click actions** — Reveal in Finder, Move to Trash (ancestor sizes are
  recalculated immediately)
- Skips symlinks and mounted volumes, so there are no cycles and external disks
  stay out of the scan
- Folders that can't be read due to missing permissions are skipped gracefully

## Requirements

- macOS 15 (Sequoia) or later
- Xcode 16+ / Swift 6 toolchain (build only)

No third-party dependencies — pure SwiftUI and Foundation.

## Building and running

```bash
# Development run
swift run

# Build a proper .app bundle
./build-app.sh
open build/Gigavore.app
```

## Permissions

- macOS will ask for access the first time you scan Desktop, Documents, or Downloads.
- Scanning the entire disk (`/`) requires **Full Disk Access**:
  System Settings → Privacy & Security → Full Disk Access → add Gigavore
  (or your terminal if you run it via `swift run`).

## Project layout

| Path | Purpose |
| --- | --- |
| `Sources/Gigavore/Scanner/DiskScanner.swift` | Recursive scanner using allocated sizes (`totalFileAllocatedSize`) |
| `Sources/Gigavore/Treemap/Squarify.swift` | Squarified treemap layout algorithm |
| `Sources/Gigavore/AppModel.swift` | App state, navigation, file actions (Trash, Finder) |
| `Sources/Gigavore/Views/` | Welcome / scanning progress / results (treemap + list) |
| `scripts/generate-icon.swift` | Renders the app icon (treemap under a magnifying lens) |

## Regenerating the icon

```bash
./scripts/generate-icon.sh
```

This renders a 1024×1024 PNG with CoreGraphics and packages it into
`Resources/AppIcon.icns` via `sips` + `iconutil`.

## License

MIT
