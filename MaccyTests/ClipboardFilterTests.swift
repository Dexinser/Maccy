import AppKit
import Defaults
import XCTest
@testable import Maccy

@MainActor
class ClipboardFilterTests: XCTestCase {
  let history = History.shared
  let savedSearchMode = Defaults[.searchMode]
  let savedSize = Defaults[.size]
  let savedSortBy = Defaults[.sortBy]

  override func setUp() {
    super.setUp()
    history.clearAll()
    Defaults[.size] = 10
    Defaults[.sortBy] = .firstCopiedAt
    Defaults[.searchMode] = .exact
    history.activeFilter = .all
    history.searchQuery = ""
    history.recomputeVisibleItemsForTesting()
  }

  override func tearDown() {
    super.tearDown()
    history.clearAll()
    Defaults[.size] = savedSize
    Defaults[.sortBy] = savedSortBy
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

    let favorite = HistoryItemDecorator(historyItem(text: "favorite"))
    favorite.toggleFavorite()
    XCTAssertTrue(ClipboardFilter.favorites.matches(favorite))
    XCTAssertFalse(ClipboardFilter.favorites.matches(mixedDecorator))
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

  func testHistoryAppliesFavoritesFilter() {
    let favorite = history.add(historyItem(text: "favorite"))
    favorite.toggleFavorite()
    let regular = history.add(historyItem(text: "regular"))

    history.activeFilter = .favorites
    history.recomputeVisibleItemsForTesting()

    XCTAssertEqual(history.items, [favorite])
    XCTAssertFalse(history.items.contains(regular))
  }

  func testUnfavoritingVisibleFavoriteRemovesItFromFavoritesFilter() {
    let favorite = history.add(historyItem(text: "favorite"))
    favorite.toggleFavorite()
    history.activeFilter = .favorites
    history.recomputeVisibleItemsForTesting()

    history.toggleFavorite(favorite)

    XCTAssertEqual(history.items, [])
  }

  func testAddingDuplicatePreservesFavorite() {
    let favorite = history.add(historyItem(text: "favorite"))
    favorite.toggleFavorite()
    history.add(historyItem(text: "regular"))

    history.add(historyItem(text: "favorite"))

    XCTAssertEqual(history.all.filter { $0.text == "favorite" }.count, 1)
    XCTAssertTrue(history.all.first { $0.text == "favorite" }?.isFavorite == true)
  }

  func testAddingDuplicateFavoriteDoesNotEvictRegularHistoryAtMaxSize() {
    let favorite = history.add(historyItem(text: "favorite"))
    history.toggleFavorite(favorite)
    let regularTexts = (1...10).map(String.init)
    regularTexts.forEach { history.add(historyItem(text: $0)) }

    let duplicateFavorite = history.add(historyItem(text: "favorite"))

    XCTAssertTrue(duplicateFavorite.isFavorite)
    XCTAssertEqual(history.all.filter(\.isDisposable).count, 10)
    XCTAssertEqual(Set(history.all.map(\.text)), Set(["favorite"] + regularTexts))
  }

  func testClearingKeepsFavorites() {
    let favorite = history.add(historyItem(text: "favorite"))
    favorite.toggleFavorite()
    history.add(historyItem(text: "regular"))

    history.clear()

    XCTAssertEqual(history.all, [favorite])
    XCTAssertEqual(history.items, [favorite])
  }

  func testMaxSizeIgnoresFavorites() {
    var items: [HistoryItemDecorator] = []

    let favorite = history.add(historyItem(text: "0"))
    items.append(favorite)
    favorite.toggleFavorite()

    for index in 1...11 {
      items.append(history.add(historyItem(text: String(index))))
    }

    XCTAssertEqual(history.all.count, 11)
    XCTAssertTrue(history.all.contains(items[10]))
    XCTAssertTrue(history.all.contains(items[0]))
    XCTAssertFalse(history.all.contains(items[1]))
  }

  func testUnfavoritingTrimsHistoryToMaxDisposableSize() {
    let favorite = history.add(historyItem(text: "favorite"))
    history.toggleFavorite(favorite)

    for index in 1...10 {
      history.add(historyItem(text: String(index)))
    }

    history.toggleFavorite(favorite)

    XCTAssertEqual(history.all.filter(\.isDisposable).count, 10)
    XCTAssertFalse(history.all.contains(favorite))
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
