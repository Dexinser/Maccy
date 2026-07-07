import XCTest
@testable import Maccy

@MainActor
final class HistoryDuplicateIndexTests: XCTestCase {
  func testCandidatesOnlyIncludeItemsSharingComparableContent() {
    let target = historyItemDecorator("target")
    let unrelatedItems = (0..<500).map { historyItemDecorator("unrelated-\($0)") }
    let index = HistoryDuplicateIndex(items: unrelatedItems + [target])

    let candidates = index.candidates(for: historyItem("target"))

    XCTAssertEqual(candidates.count, 1)
    XCTAssertTrue(candidates.first === target.item)
  }

  func testCandidatesIncludeSupersetItems() {
    let superset = historyItemDecorator([
      HistoryItemContent(
        type: NSPasteboard.PasteboardType.string.rawValue,
        value: "plain".data(using: .utf8)
      ),
      HistoryItemContent(
        type: NSPasteboard.PasteboardType.rtf.rawValue,
        value: "rich".data(using: .utf8)
      )
    ])
    let index = HistoryDuplicateIndex(items: [historyItemDecorator("other"), superset])

    let candidates = index.candidates(for: historyItem("plain"))

    XCTAssertEqual(candidates.count, 1)
    XCTAssertTrue(candidates.first === superset.item)
  }

  func testTransientContentDoesNotCreateCandidates() {
    let item = historyItemDecorator([
      HistoryItemContent(
        type: NSPasteboard.PasteboardType.modified.rawValue,
        value: "1".data(using: .utf8)
      )
    ])
    let index = HistoryDuplicateIndex(items: [item])

    XCTAssertEqual(index.candidates(for: historyItem([
      HistoryItemContent(
        type: NSPasteboard.PasteboardType.modified.rawValue,
        value: "1".data(using: .utf8)
      )
    ])).count, 0)
  }

  func testInsertRemoveAndReorderMaintainCandidateOrder() {
    let first = historyItemDecorator("shared")
    let second = historyItemDecorator("shared")
    let third = historyItemDecorator("shared")
    var index = HistoryDuplicateIndex(items: [first])

    index.insert(second, at: 0)
    index.insert(third, at: 2)

    XCTAssertEqual(index.candidates(for: historyItem("shared")).map(\.title), [
      second.title,
      first.title,
      third.title
    ])

    index.remove(first)
    XCTAssertEqual(index.candidates(for: historyItem("shared")).map(\.title), [
      second.title,
      third.title
    ])

    index.reorder(with: [third, second])
    XCTAssertEqual(index.candidates(for: historyItem("shared")).map(\.title), [
      third.title,
      second.title
    ])
  }

  private func historyItemDecorator(_ value: String) -> HistoryItemDecorator {
    HistoryItemDecorator(historyItem(value))
  }

  private func historyItemDecorator(_ contents: [HistoryItemContent]) -> HistoryItemDecorator {
    HistoryItemDecorator(historyItem(contents))
  }

  private func historyItem(_ value: String) -> HistoryItem {
    historyItem([
      HistoryItemContent(
        type: NSPasteboard.PasteboardType.string.rawValue,
        value: value.data(using: .utf8)
      )
    ])
  }

  private func historyItem(_ contents: [HistoryItemContent]) -> HistoryItem {
    let item = HistoryItem()
    Storage.shared.context.insert(item)
    item.contents = contents
    item.title = item.generateTitle()
    return item
  }
}
