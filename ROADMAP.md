# Roadmap

MenuBarNotes stays deliberately small: a menu bar window, plain `.md` files you
own, and no account. This roadmap lists what is shipped and what is next.

## Shipped

- [x] Menu bar only app (`LSUIElement`), no Dock icon
- [x] Markdown editor with live preview (headings, lists, code, task checkboxes)
- [x] Global show/hide hotkey `⌘⇧N`
- [x] Sync-safe storage with `NSFileCoordinator`/`NSFilePresenter` and atomic writes
- [x] Brand mark in the menu bar, app icon, and About panel
- [x] Instant sidebar search
- [x] Pin a note to the top of the list
- [x] Delete to the macOS Trash instead of permanent removal
- [x] Quick capture: `⌥⌘N` opens the popover with a new note
- [x] Word count and last-saved time in the editor header
- [x] Hardened file access, local-only networking, no analytics

## Next

- [ ] Note renaming from the sidebar (with collision handling)
- [ ] Floating quick-capture panel that does not steal focus from the current app
- [ ] Markdown export (HTML/PDF) and print
- [ ] Optional custom notes folder (menu item to pick a synced directory)
- [ ] Light/dark preview themes and adjustable editor width
- [ ] Shortcuts action for append-to-daily-note

## Later / exploring

- [ ] Per-note tags as front matter, with a filter bar
- [ ] Encrypted notes (FileVault is the current answer; per-note encryption is not)
- [ ] iOS/iPadOS companion reading the same iCloud folder
- [ ] Sparkle-based automatic updates

## Not planned

- Accounts, sync servers, or telemetry
- Rich-text/WYSIWYG editing — the file stays readable markdown
- Plugin system
