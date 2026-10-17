<p align="center">
  <img src="assets/logo-256.png" width="128" height="128" alt="MenuBarNotes app icon">
</p>

<h1 align="center">MenuBarNotes</h1>

<p align="center">A tiny menu bar markdown notebook — plain files, no lock-in.</p>

A lightweight macOS 15+ menu bar note-taking app. Notes are plain-text `.md` files in `~/Documents/MenuBarNotes` — no database, no lock-in.

## Features

- Menu bar only (`LSUIElement`) — no Dock icon
- Markdown editor with real-time preview (headings, lists, code blocks, task checkboxes)
- Global hotkeys: `⌘⇧N` shows/hides the popover, `⌥⌘N` quick-captures a new note
- Instant search, pin-to-top, and move-to-Trash in the sidebar
- Word count and last-saved time while you type
- Sync-safe storage: atomic writes + `NSFileCoordinator`/`NSFilePresenter`, so iCloud Drive, Dropbox, OneDrive and Google Drive can sync the folder without corrupting notes — external changes reload live
- Plain `.md` files in `~/Documents/MenuBarNotes` (right-click the menu bar icon → Open Notes Folder)

## Hotkeys

| Shortcut | Action |
| --- | --- |
| `⌘⇧N` | Show or hide the notes popover |
| `⌥⌘N` | Quick capture: open the popover with a new note |
| `⌘Q` | Quit (from the menu bar menu) |

## Performance & battery

- The SwiftUI popover is built when you open it and released when it closes; a
  hidden MenuBarNotes does no layout, animation, or redraw work
- Markdown re-parses after a 180 ms typing pause instead of on every keystroke
- Saves are debounced (400 ms) and skipped when the text is unchanged; closing the
  popover flushes immediately
- Cloud-sync notifications are coalesced so a burst of file changes triggers one
  folder scan
- No polling timers, background refresh, or network activity — the app uses 0% CPU
  when the window is closed

## Security & privacy

- Only touches `~/Documents/MenuBarNotes`; symlinks, non-regular files, and files over 2 MB are refused
- Atomic, file-coordinated writes; deletes go to the macOS Trash
- No network calls, no analytics, no accounts — see [SECURITY.md](SECURITY.md)
- Preview links are limited to `http`, `https`, and `mailto`

## Roadmap

See [ROADMAP.md](ROADMAP.md) for shipped and planned features.

## Build

```sh
swift build -c release            # or: xcodebuild -scheme MenuBarNotes -configuration Release
./scripts/package-app.sh .build/release/MenuBarNotes
open MenuBarNotes.app
```

## Releases

Push to `main` (or a `v*` tag): GitHub Actions builds `MenuBarNotes.zip` and publishes a GitHub Release with auto-generated release notes.
