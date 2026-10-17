import XCTest
@testable import MenuBarNotes

final class NoteListTests: XCTestCase {
    private func note(_ name: String) -> Note {
        Note(url: URL(fileURLWithPath: "/tmp/MenuBarNotes/\(name).md"))
    }

    func testPinnedNoteSortsFirst() {
        let notes = [note("Beta"), note("Alpha"), note("Gamma")]
        let arranged = NoteOrdering.arrange(notes, pinnedFileName: "Gamma.md")
        XCTAssertEqual(arranged.map(\.name), ["Gamma", "Alpha", "Beta"])
    }

    func testNaturalFileNameOrdering() {
        let notes = [note("Note 10"), note("Note 2")]
        XCTAssertEqual(NoteOrdering.arrange(notes, pinnedFileName: nil).map(\.name), ["Note 2", "Note 10"])
    }

    func testSearchIsCaseInsensitiveAndTrimsWhitespace() {
        let notes = [note("Groceries"), note("Ideas")]
        XCTAssertEqual(NoteOrdering.filter(notes, query: "  groc ").map(\.name), ["Groceries"])
        XCTAssertEqual(NoteOrdering.filter(notes, query: "   ").count, 2)
    }

    func testWordCount() {
        XCTAssertEqual(NoteMetrics.wordCount(in: "one two\nthree\tfour"), 4)
        XCTAssertEqual(NoteMetrics.wordCount(in: "   "), 0)
    }
}
