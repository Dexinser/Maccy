import XCTest
@testable import Maccy

final class PreviewTextSelectionTests: XCTestCase {
  func testCopySelectionIsAvailableOnlyWhenSelectionIsNotEmpty() {
    let selection = PreviewTextSelection()

    XCTAssertFalse(selection.canCopySelection)

    selection.update(selectedText: "fragment")

    XCTAssertTrue(selection.canCopySelection)

    selection.update(selectedText: "")

    XCTAssertFalse(selection.canCopySelection)
  }

  func testSelectedTextPreservesUserWhitespace() {
    let selection = PreviewTextSelection()
    let selectedText = "  keep\nthis\tspacing  "

    selection.update(selectedText: selectedText)

    XCTAssertEqual(selection.textForCopy, selectedText)
  }

  func testResetClearsSelection() {
    let selection = PreviewTextSelection()
    selection.update(selectedText: "fragment")

    selection.reset()

    XCTAssertEqual(selection.textForCopy, "")
    XCTAssertFalse(selection.canCopySelection)
  }
}
