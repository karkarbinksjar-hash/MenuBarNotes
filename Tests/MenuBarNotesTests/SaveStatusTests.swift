import XCTest
@testable import MenuBarNotes

final class SaveStatusTests: XCTestCase {
    func testChangedTextIsUnsaved() {
        XCTAssertEqual(NoteSaveStatus.compute(isSaving: false, currentText: "new", persistedText: "old"), .unsaved)
    }

    func testMissingPersistedContentIsNeverTreatedAsSaved() {
        XCTAssertEqual(NoteSaveStatus.compute(isSaving: false, currentText: "draft", persistedText: nil), .unsaved)
    }

    func testSavingTakesPriorityAndMatchingTextIsSaved() {
        XCTAssertEqual(NoteSaveStatus.compute(isSaving: true, currentText: "same", persistedText: "same"), .saving)
        XCTAssertEqual(NoteSaveStatus.compute(isSaving: false, currentText: "same", persistedText: "same"), .saved)
    }
}
