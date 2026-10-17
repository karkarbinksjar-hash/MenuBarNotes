import XCTest
@testable import MenuBarNotes

final class MarkdownParserTests: XCTestCase {
    func testBlocks() {
        let source = """
        # Title

        First paragraph
        with a wrap.

        - [x] done task
        - [ ] open task
        - plain bullet

        ```swift
        let x = 1
        ```

        1. numbered
        """
        XCTAssertEqual(parseMarkdown(source), [
            .heading(level: 1, text: "Title"),
            .paragraph("First paragraph with a wrap."),
            .task(done: true, text: "done task"),
            .task(done: false, text: "open task"),
            .bullet("plain bullet"),
            .code("let x = 1"),
            .numbered("numbered"),
        ])
    }

    func testUnclosedCodeFenceKeepsText() {
        XCTAssertEqual(parseMarkdown("```\nno end"), [.code("no end")])
    }
}
