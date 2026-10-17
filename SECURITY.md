# Security

MenuBarNotes is a local-only menu bar app. It has no accounts, no servers, no
analytics, and makes no network requests.

## What the app can access

- **Notes folder**: `~/Documents/MenuBarNotes` and nothing else. Reads and writes
  are refused for paths outside this directory, symbolic links, non-regular
  files, and files larger than 2 MB.
- **User defaults**: only the pinned note's filename.
- **No network**: there is no networking code, no update checker, and no telemetry.

## Storage behaviour

- Writes are atomic and wrapped in `NSFileCoordinator` so cloud-sync clients never
  see a partial file.
- Deletes move the note to the macOS Trash, so a mistaken delete is recoverable.
- The notes directory is created with `0700` permissions on first launch.
- Note previews only make `http`, `https`, and `mailto` links tappable; other URL
  schemes (including `file:` and custom schemes) are rendered as plain text.

## Distribution

Release builds are ad-hoc signed with the hardened runtime enabled. They are not
notarized; signed/notarized builds are on the roadmap.

## Reporting a vulnerability

Open a private security advisory on GitHub
(<https://github.com/karkarbinksjar-hash/MenuBarNotes/security/advisories/new>)
or email the maintainer listed on the repository profile. Please include the app
version and reproduction steps. Do not file a public issue for an unpatched
vulnerability.
