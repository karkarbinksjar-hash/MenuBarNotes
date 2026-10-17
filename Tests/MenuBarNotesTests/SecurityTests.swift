import XCTest
@testable import MenuBarNotes

final class SecurityTests: XCTestCase {
    private var root: URL!
    private var outside: URL!

    override func setUpWithError() throws {
        let base = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        root = base.appendingPathComponent("MenuBarNotes", isDirectory: true)
        outside = base.appendingPathComponent("Outside", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: outside, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: root.deletingLastPathComponent())
    }

    func testRegularNoteIsSafe() throws {
        let note = root.appendingPathComponent("Note.md")
        try "hello".write(to: note, atomically: true, encoding: .utf8)
        XCTAssertTrue(FileSafety.isSafeNote(note, in: root))
        XCTAssertTrue(FileSafety.isSafeDestination(note, in: root))
    }

    func testSymlinkInsideFolderIsRefused() throws {
        let secret = outside.appendingPathComponent("secret.md")
        try "secret".write(to: secret, atomically: true, encoding: .utf8)
        let link = root.appendingPathComponent("Link.md")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: secret)

        XCTAssertFalse(FileSafety.isSafeNote(link, in: root))
        XCTAssertFalse(FileSafety.isSafeDestination(link, in: root))
    }

    func testPathsOutsideFolderAreRefused() {
        let outsideNote = outside.appendingPathComponent("Other.md")
        XCTAssertFalse(FileSafety.isSafeNote(outsideNote, in: root))
        XCTAssertFalse(FileSafety.isSafeDestination(outsideNote, in: root))

        let escape = root.appendingPathComponent("..").appendingPathComponent("Escape.md")
        XCTAssertFalse(FileSafety.isSafeDestination(escape, in: root))
    }

    func testOversizedFileDetection() throws {
        let big = root.appendingPathComponent("Big.md")
        try Data(count: FileSafety.maxNoteBytes + 1).write(to: big)
        XCTAssertTrue(FileSafety.isOversized(big))
    }

    func testOnlyWebAndMailLinksSurvive() {
        XCTAssertTrue(InlineMarkdown.isAllowed(URL(string: "https://example.com")!))
        XCTAssertTrue(InlineMarkdown.isAllowed(URL(string: "http://example.com")!))
        XCTAssertTrue(InlineMarkdown.isAllowed(URL(string: "mailto:hi@example.com")!))
        XCTAssertFalse(InlineMarkdown.isAllowed(URL(string: "file:///etc/passwd")!))
        XCTAssertFalse(InlineMarkdown.isAllowed(URL(string: "javascript:alert(1)")!))
        XCTAssertFalse(InlineMarkdown.isAllowed(URL(string: "menubarnotes://run")!))
    }

    func testUnsafeLinksAreStrippedFromPreview() {
        let rendered = InlineMarkdown.attributed("[click](file:///etc/passwd)")
        XCTAssertNil(rendered.runs.first?.link)
    }
}
