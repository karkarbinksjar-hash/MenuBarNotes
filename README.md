<p align="center">
  <img src="assets/logo-256.png" width="128" height="128" alt="MenuBarNotes app icon">
</p>

<h1 align="center">MenuBarNotes</h1>

<p align="center">A tiny menu bar markdown notebook — plain files, no lock-in.</p>

A lightweight macOS 15+ menu bar note-taking app. Notes are plain-text `.md` files in `~/Documents/MenuBarNotes` — no database, no lock-in.

## Features

- Menu bar only (`LSUIElement`) — no Dock icon
- Markdown editor with real-time preview (headings, lists, code blocks, task checkboxes)
- Global hotkey `Cmd+Shift+N` to show/hide the popover
- Sync-safe storage: atomic writes + `NSFileCoordinator`/`NSFilePresenter`, so iCloud Drive, Dropbox, OneDrive and Google Drive can sync the folder without corrupting notes — external changes reload live

## Build

```sh
swift build -c release            # or: xcodebuild -scheme MenuBarNotes -configuration Release
./scripts/package-app.sh .build/release/MenuBarNotes
open MenuBarNotes.app
```

## Releases

Push to `main` (or a `v*` tag): GitHub Actions builds `MenuBarNotes.zip` and publishes a GitHub Release with auto-generated release notes.
