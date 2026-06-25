import AppKit
import Defaults
import XCTest
@testable import Maccy

@MainActor
class ClipboardFilterTests: XCTestCase {
  let history = History.shared
  let savedSearchMode = Defaults[.searchMode]

  override func setUp() {
    super.setUp()
    history.clearAll()
    Defaults[.searchMode] = .exact
  }

  override func tearDown() {
    super.tearDown()
    history.clearAll()
    Defaults[.searchMode] = savedSearchMode
  }

  func testTextItemKind() {
    XCTAssertEqual(historyItem(text: "hello").kind, .text)
    XCTAssertEqual(HistoryItemDecorator(historyItem(text: "hello")).kind, .text)
  }

  func testImageItemKind() {
    let image = NSImage(named: "NSBluetoothTemplate")!
    XCTAssertEqual(historyItem(image: image).kind, .image)
    XCTAssertEqual(HistoryItemDecorator(historyItem(image: image)).kind, .image)
  }

  func testFileItemKind() {
    let url = URL(fileURLWithPath: "/tmp/example.txt")
    XCTAssertEqual(historyItem(fileURL: url).kind, .file)
    XCTAssertEqual(HistoryItemDecorator(historyItem(fileURL: url)).kind, .file)
  }

  func testMixedItemKind() {
    let image = NSImage(named: "NSBluetoothTemplate")!
    let url = URL(fileURLWithPath: "/tmp/example.txt")
    let item = HistoryItem()
    Storage.shared.context.insert(item)
    item.contents = [
      HistoryItemContent(
        type: NSPasteboard.PasteboardType.tiff.rawValue,
        value: image.tiffRepresentation!
      ),
      HistoryItemContent(
        type: NSPasteboard.PasteboardType.fileURL.rawValue,
        value: url.dataRepresentation
      )
    ]
    item.title = item.generateTitle()

    XCTAssertEqual(item.kind, .mixed)
    XCTAssertEqual(HistoryItemDecorator(item).kind, .mixed)
  }

  func testClipboardFilterMatching() {
    XCTAssertTrue(ClipboardFilter.all.matches(.text))
    XCTAssertTrue(ClipboardFilter.text.matches(.text))
    XCTAssertFalse(ClipboardFilter.text.matches(.image))
    XCTAssertTrue(ClipboardFilter.images.matches(.image))
    XCTAssertFalse(ClipboardFilter.images.matches(.mixed))
    XCTAssertTrue(ClipboardFilter.files.matches(.file))
    XCTAssertFalse(ClipboardFilter.files.matches(.text))
  }

  func testHistoryAppliesSearchThenTypeFilterAndKeepsUntitledImagesVisible() {
    let text = history.add(historyItem(text: "alpha"))
    let image = history.add(historyItem(image: NSImage(named: "NSBluetoothTemplate")!))

    history.searchQuery = ""
    waitForThrottle()

    history.activeFilter = .images
    waitForThrottle()
    XCTAssertEqual(history.items, [image])

    history.activeFilter = .text
    waitForThrottle()
    XCTAssertEqual(history.items, [text])

    history.searchQuery = "alpha"
    waitForThrottle()
    XCTAssertEqual(history.items, [text])

    history.activeFilter = .images
    waitForThrottle()
    XCTAssertEqual(history.items, [])
  }

  private func historyItem(text: String) -> HistoryItem {
    let item = HistoryItem()
    Storage.shared.context.insert(item)
    item.contents = [
      HistoryItemContent(
        type: NSPasteboard.PasteboardType.string.rawValue,
        value: text.data(using: .utf8)
      )
    ]
    item.title = item.generateTitle()
    return item
  }

  private func historyItem(image: NSImage) -> HistoryItem {
    let item = HistoryItem()
    Storage.shared.context.insert(item)
    item.contents = [
      HistoryItemContent(
        type: NSPasteboard.PasteboardType.tiff.rawValue,
        value: image.tiffRepresentation!
      )
    ]
    item.title = item.generateTitle()
    return item
  }

  private func historyItem(fileURL: URL) -> HistoryItem {
    let item = HistoryItem()
    Storage.shared.context.insert(item)
    item.contents = [
      HistoryItemContent(
        type: NSPasteboard.PasteboardType.fileURL.rawValue,
        value: fileURL.dataRepresentation
      ),
      HistoryItemContent(
        type: NSPasteboard.PasteboardType.string.rawValue,
        value: fileURL.lastPathComponent.data(using: .utf8)
      )
    ]
    item.title = item.generateTitle()
    return item
  }

  private func waitForThrottle() {
    let expectation = expectation(description: "wait for throttled history update")
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
      expectation.fulfill()
    }
    wait(for: [expectation], timeout: 1.0)
  }
}
