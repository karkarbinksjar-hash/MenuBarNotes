import Foundation

/// Guards around the single directory MenuBarNotes is allowed to touch.
/// Notes live in `~/Documents/MenuBarNotes`; anything that resolves outside it
/// (symlinks planted by another app, hostile sync payloads) is refused.
enum FileSafety {
    /// Notes are plain text. Anything beyond this is almost certainly not a note
    /// and is refused rather than loaded into memory or overwritten.
    static let maxNoteBytes = 2 * 1024 * 1024

    /// A readable note: a regular, non-symlinked file directly inside `directory`.
    static func isSafeNote(_ url: URL, in directory: URL) -> Bool {
        guard isDirectChild(url, of: directory) else { return false }
        guard let values = try? url.resourceValues(forKeys: [.isSymbolicLinkKey, .isRegularFileKey]) else {
            return false
        }
        return values.isSymbolicLink != true && values.isRegularFile == true
    }

    /// A writable destination: directly inside `directory`, and if the file already
    /// exists it must be a safe regular file (never a symlink to somewhere else).
    static func isSafeDestination(_ url: URL, in directory: URL) -> Bool {
        guard isDirectChild(url, of: directory) else { return false }
        if FileManager.default.fileExists(atPath: url.path) {
            return isSafeNote(url, in: directory)
        }
        return true
    }

    static func isOversized(_ url: URL, limit: Int = FileSafety.maxNoteBytes) -> Bool {
        guard let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize else {
            return false
        }
        return size > limit
    }

    private static func isDirectChild(_ url: URL, of directory: URL) -> Bool {
        let name = url.lastPathComponent
        guard !name.isEmpty, name != ".", name != ".." else { return false }
        let parent = url.deletingLastPathComponent().resolvingSymlinksInPath().standardizedFileURL
        let root = directory.resolvingSymlinksInPath().standardizedFileURL
        return parent == root
    }
}
