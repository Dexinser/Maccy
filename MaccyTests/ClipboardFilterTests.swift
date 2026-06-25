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
    history.activeFilter = .all
    history.searchQuery = ""
    history.recomputeVisibleItemsForTesting()
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
    let item = mixedHistoryItem(
      string: "hello",
      image: NSImage(named: "NSBluetoothTemplate")!,
      fileURL: URL(fileURLWithPath: "/tmp/example.txt")
    )

    XCTAssertEqual(item.kind, .mixed)
    XCTAssertEqual(HistoryItemDecorator(item).kind, .mixed)
  }

  func testClipboardFilterMatching() {
    let mixedTextImageFile = mixedHistoryItem(
      string: "hello",
      image: NSImage(named: "NSBluetoothTemplate")!,
      fileURL: URL(fileURLWithPath: "/tmp/example.txt")
    )
    let mixedDecorator = HistoryItemDecorator(mixedTextImageFile)

    XCTAssertTrue(ClipboardFilter.text.matches(mixedDecorator))
    XCTAssertTrue(ClipboardFilter.images.matches(mixedDecorator))
    XCTAssertTrue(ClipboardFilter.files.matches(mixedDecorator))

    let universalImage = universalClipboardImageItem()
    XCTAssertTrue(ClipboardFilter.images.matches(universalImage))
    XCTAssertFalse(ClipboardFilter.text.matches(universalImage))
  }

  func testHistoryAppliesSearchThenTypeFilterAndKeepsUntitledImagesVisible() {
    let text = history.add(historyItem(text: "alpha"))
    let image = history.add(historyItem(image: NSImage(named: "NSBluetoothTemplate")!))

    history.activeFilter = .images
    history.recomputeVisibleItemsForTesting()
    XCTAssertEqual(history.items, [image])

    history.activeFilter = .text
    history.recomputeVisibleItemsForTesting()
    XCTAssertEqual(history.items, [text])

    history.searchQuery = "alpha"
    history.recomputeVisibleItemsForTesting()
    XCTAssertEqual(history.items, [text])

    history.activeFilter = .images
    history.recomputeVisibleItemsForTesting()
    XCTAssertEqual(history.items, [])
  }

  func testRecomputeSelectsPinnedItemWhenOnlyPinnedItemsAreVisible() {
    let pinned = history.add(historyItem(text: "pinned"))
    pinned.togglePin()

    AppState.shared.navigator.selectWithoutScrolling(item: nil)

    history.recomputeVisibleItemsForTesting()

    XCTAssertEqual(history.items, [pinned])
    XCTAssertEqual(AppState.shared.navigator.selection.first, pinned)
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

  private func mixedHistoryItem(string: String, image: NSImage, fileURL: URL) -> HistoryItem {
    let item = HistoryItem()
    Storage.shared.context.insert(item)
    item.contents = [
      HistoryItemContent(
        type: NSPasteboard.PasteboardType.string.rawValue,
        value: string.data(using: .utf8)
      ),
      HistoryItemContent(
        type: NSPasteboard.PasteboardType.tiff.rawValue,
        value: image.tiffRepresentation!
      ),
      HistoryItemContent(
        type: NSPasteboard.PasteboardType.fileURL.rawValue,
        value: fileURL.dataRepresentation
      )
    ]
    item.title = item.generateTitle()
    return item
  }

  private func universalClipboardImageItem() -> HistoryItem {
    let url = Bundle(for: type(of: self)).url(forResource: "guy", withExtension: "jpeg")!
    let item = HistoryItem()
    Storage.shared.context.insert(item)
    item.contents = [
      HistoryItemContent(
        type: NSPasteboard.PasteboardType.fileURL.rawValue,
        value: url.dataRepresentation
      ),
      HistoryItemContent(
        type: NSPasteboard.PasteboardType.jpeg.rawValue,
        value: try? Data(contentsOf: url)
      ),
      HistoryItemContent(
        type: NSPasteboard.PasteboardType.universalClipboard.rawValue,
        value: "".data(using: .utf8)
      )
    ]
    return item
  }

}
