import Foundation

struct Note: Identifiable, Equatable, Hashable {
    let url: URL
    var id: URL { url }
    var name: String { url.deletingPathExtension().lastPathComponent }
    var fileName: String { url.lastPathComponent }
}

/// Pure list operations, kept separate from disk access so they are easy to test.
enum NoteOrdering {
    /// Pinned note first, then filename order (Finder-style natural sorting).
    static func arrange(_ notes: [Note], pinnedFileName: String?) -> [Note] {
        notes.sorted { lhs, rhs in
            let lhsPinned = lhs.fileName == pinnedFileName
            let rhsPinned = rhs.fileName == pinnedFileName
            if lhsPinned != rhsPinned { return lhsPinned }
            return lhs.fileName.localizedStandardCompare(rhs.fileName) == .orderedAscending
        }
    }

    /// Case-insensitive filename search. An empty query returns everything.
    static func filter(_ notes: [Note], query: String) -> [Note] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return notes }
        return notes.filter { $0.name.localizedCaseInsensitiveContains(trimmed) }
    }
}

enum NoteMetrics {
    static func wordCount(in text: String) -> Int {
        text.split(whereSeparator: { $0.isWhitespace }).count
    }

    static func characterCount(in text: String) -> Int {
        text.count
    }
}
