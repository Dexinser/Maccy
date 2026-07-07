import XCTest
import Defaults
@testable import Maccy

@MainActor
class HistoryItemDecoratorTests: XCTestCase {
  let boldFont = NSFont.boldSystemFont(ofSize: NSFont.systemFontSize)
  let savedHighlightMatch = Defaults[.highlightMatch]
  let savedImageMaxHeight = Defaults[.imageMaxHeight]

  var firstCopiedAt: Date! {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
    return formatter.date(from: "2020/07/10 12:31:34")
  }

  var lastCopiedAt: Date! {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
    return formatter.date(from: "2020/07/10 12:41:34")
  }

  override func setUp() {
    super.setUp()
    Defaults[.highlightMatch] = .bold
    Defaults[.imageMaxHeight] = 40
  }

  override func tearDown() {
    super.tearDown()
    Defaults[.imageMaxHeight] = savedImageMaxHeight
    Defaults[.highlightMatch] = savedHighlightMatch
  }

  func testString() {
    let title = "foo"
    let itemDecorator = historyItemDecorator(title)
    XCTAssertEqual(itemDecorator.title, title)
    XCTAssertNil(itemDecorator.previewImage)
    XCTAssertNil(itemDecorator.thumbnailImage)
  }

  func testTextPreviewUsesFullClipboardTextEvenWhenTitleIsShortened() {
    let suffix = " unique text after preview cutoff"
    let text = String(repeating: "a", count: 12_000) + suffix
    let itemDecorator = historyItemDecorator(text)

    XCTAssertFalse(itemDecorator.title.contains(suffix))
    XCTAssertEqual(itemDecorator.text, text)
    XCTAssertTrue(itemDecorator.text.contains(suffix))
  }

  func testRTF() {
    let rtf = NSAttributedString(string: "foo").rtf(
      from: NSRange(0...2),
      documentAttributes: [:]
    )
    let itemDecorator = historyItemDecorator(rtf, .rtf)
    XCTAssertEqual(itemDecorator.title, "foo")
    XCTAssertNil(itemDecorator.previewImage)
    XCTAssertNil(itemDecorator.thumbnailImage)
  }

  func testHTML() {
    let html = "<a href='#'>foo</a>".data(using: .utf8)
    let itemDecorator = historyItemDecorator(html, .html)
    XCTAssertEqual(itemDecorator.title, "foo")
    XCTAssertNil(itemDecorator.previewImage)
    XCTAssertNil(itemDecorator.thumbnailImage)
  }

  func testImage() {
    let image = NSImage(named: "StatusBarMenuImage")!
    let itemDecorator = historyItemDecorator(image)
    itemDecorator.sizeImages()
    XCTAssertEqual(itemDecorator.title, "")
    XCTAssertEqual(itemDecorator.listTitle, "")
    XCTAssertEqual(itemDecorator.previewImage!.size, image.size)
    XCTAssertEqual(itemDecorator.thumbnailImage!.size, image.size)
  }

  func testPureImageListTitleDoesNotExposeRecognizedImageText() {
    let itemDecorator = historyItemDecorator(NSImage(named: "StatusBarMenuImage")!)
    itemDecorator.item.title = "Recognized screenshot text"
    itemDecorator.title = itemDecorator.item.title

    XCTAssertEqual(itemDecorator.title, "Recognized screenshot text")
    XCTAssertEqual(itemDecorator.listTitle, "")
    XCTAssertNotNil(itemDecorator.listAccessoryImage)
  }

  func testMixedImageListTitleDoesNotExposeClipboardText() {
    let itemDecorator = historyItemDecorator(
      text: "Maccy Q W screenshot text",
      image: NSImage(named: "StatusBarMenuImage")!
    )
    itemDecorator.title = "Maccy Q W screenshot text"
    itemDecorator.item.title = itemDecorator.title

    XCTAssertTrue(itemDecorator.containsImage)
    XCTAssertTrue(itemDecorator.containsText)
    XCTAssertEqual(itemDecorator.listTitle, "")
    XCTAssertNotNil(itemDecorator.listAccessoryImage)
  }

  func testMixedImageRowsDoNotRenderTitleViewBeforeThumbnailGenerated() {
    let itemDecorator = historyItemDecorator(
      text: "Maccy Q W screenshot text",
      image: NSImage(named: "StatusBarMenuImage")!
    )
    itemDecorator.title = "Maccy Q W screenshot text"
    itemDecorator.item.title = itemDecorator.title

    XCTAssertTrue(itemDecorator.containsImage)
    XCTAssertNil(itemDecorator.thumbnailImage)
    XCTAssertFalse(itemDecorator.showsListTitle)
    XCTAssertNil(itemDecorator.listAttributedTitle)
    XCTAssertNotNil(itemDecorator.listAccessoryImage)
  }

  func testMixedImageSearchHighlightDoesNotExposeClipboardText() {
    let itemDecorator = historyItemDecorator(
      text: "Maccy Q W screenshot text",
      image: NSImage(named: "StatusBarMenuImage")!
    )
    itemDecorator.title = "Maccy Q W screenshot text"
    itemDecorator.item.title = itemDecorator.title

    itemDecorator.highlight("screenshot", [itemDecorator.title.range(of: "screenshot")!])

    XCTAssertTrue(itemDecorator.containsImage)
    XCTAssertNil(itemDecorator.attributedTitle)
  }

  func testPasteStackImagePresentationDoesNotExposeRecognizedImageText() {
    let itemDecorator = historyItemDecorator(
      text: "Maccy Q W screenshot text",
      image: NSImage(named: "StatusBarMenuImage")!
    )
    itemDecorator.title = "Maccy Q W screenshot text"
    itemDecorator.item.title = itemDecorator.title

    let presentation = PasteStackItemPresentation(item: itemDecorator, index: 0)

    XCTAssertEqual(presentation.title, "")
    XCTAssertFalse(presentation.showsTitle)
    XCTAssertNotNil(presentation.accessoryImage)
  }

  // We also need to add test for image with width bigger than max width.
  func testImageWithHeightBiggerThanMaxHeight() {
    let image = NSImage(named: "NSApplicationIcon")!
    let itemDecorator = historyItemDecorator(image)
    itemDecorator.sizeImages()
    XCTAssertEqual(itemDecorator.thumbnailImage!.size, NSSize(width: 40, height: 40))
  }

  func testResizedImageIsBitmapBackedAndBoundedToTargetSize() throws {
    let image = try bitmapImage(width: 240, height: 120)

    let resized = image.resized(to: NSSize(width: 60, height: 60))

    XCTAssertEqual(resized.size, NSSize(width: 60, height: 30))
    let bitmap = resized.representations.compactMap { $0 as? NSBitmapImageRep }.first
    XCTAssertNotNil(bitmap)
    XCTAssertLessThanOrEqual(bitmap?.pixelsWide ?? .max, 60)
    XCTAssertLessThanOrEqual(bitmap?.pixelsHigh ?? .max, 60)
  }

  func testFile() {
    let url = URL(fileURLWithPath: "/tmp/foo.bar")
    let itemDecorator = historyItemDecorator(url)
    XCTAssertEqual(itemDecorator.title, "file:///tmp/foo.bar")
    XCTAssertNil(itemDecorator.previewImage)
    XCTAssertNil(itemDecorator.thumbnailImage)
  }

  func testFileWithEscapedChars() {
    let url = URL(fileURLWithPath: "/tmp/产品培训/产品培训.txt")
    let itemDecorator = historyItemDecorator(url)
    XCTAssertEqual(itemDecorator.title, "file:///tmp/产品培训/产品培训.txt")
    XCTAssertNil(itemDecorator.previewImage)
    XCTAssertNil(itemDecorator.thumbnailImage)
  }

  func testItemWithoutData() {
    let itemDecorator = historyItemDecorator(nil)
    XCTAssertEqual(itemDecorator.title, "")
    XCTAssertNil(itemDecorator.previewImage)
    XCTAssertNil(itemDecorator.thumbnailImage)
  }

  func testUnpinnedByDefault() {
    let itemDecorator = historyItemDecorator("foo")
    XCTAssertNil(itemDecorator.item.pin)
    XCTAssertFalse(itemDecorator.isPinned)
  }

  func testPin() {
    let itemDecorator = historyItemDecorator("foo")
    itemDecorator.togglePin()
    XCTAssertNotNil(itemDecorator.item.pin)
    XCTAssertTrue(itemDecorator.isPinned)
  }

  func testUnpin() {
    let itemDecorator = historyItemDecorator("foo")
    itemDecorator.togglePin()
    itemDecorator.togglePin()
    XCTAssertNil(itemDecorator.item.pin)
    XCTAssertFalse(itemDecorator.isPinned)
  }

  func testUnfavoritedByDefault() {
    let itemDecorator = historyItemDecorator("foo")
    XCTAssertFalse(itemDecorator.item.isFavorite)
    XCTAssertFalse(itemDecorator.isFavorite)
  }

  func testToggleFavorite() {
    let itemDecorator = historyItemDecorator("foo")
    itemDecorator.toggleFavorite()
    XCTAssertTrue(itemDecorator.item.isFavorite)
    XCTAssertTrue(itemDecorator.isFavorite)

    itemDecorator.toggleFavorite()
    XCTAssertFalse(itemDecorator.item.isFavorite)
    XCTAssertFalse(itemDecorator.isFavorite)
  }

  func testHashDoesNotChangeWhenFavoriteChanges() {
    let itemDecorator = historyItemDecorator("foo")
    let initialHash = hash(itemDecorator)

    itemDecorator.toggleFavorite()

    XCTAssertEqual(hash(itemDecorator), initialHash)
  }

  func testHighlight() {
    let itemDecorator = historyItemDecorator("foo bar baz")
    itemDecorator.highlight("random", [
      range(from: 1, to: 2, in: itemDecorator),
      range(from: 8, to: 10, in: itemDecorator)
    ])
    var expectedTitle = AttributedString("foo bar baz")
    expectedTitle[expectedTitle.range(of: "oo")!].font = .bold(.body)()
    expectedTitle[expectedTitle.range(of: "baz")!].font = .bold(.body)()
    XCTAssertEqual(itemDecorator.attributedTitle, expectedTitle)
    itemDecorator.highlight("", [])
    XCTAssertEqual(itemDecorator.attributedTitle, nil)
  }

  private func historyItemDecorator(
    _ value: String?,
    application: String? = "com.apple.finder"
  ) -> HistoryItemDecorator {
    let contents = [
      HistoryItemContent(
        type: NSPasteboard.PasteboardType.string.rawValue,
        value: value?.data(using: .utf8)
      )
    ]
    let item = HistoryItem()
    Storage.shared.context.insert(item)
    item.contents = contents
    item.title = item.generateTitle()
    item.application = application
    item.firstCopiedAt = firstCopiedAt
    item.lastCopiedAt = lastCopiedAt

    return HistoryItemDecorator(item)
  }

  private func hash(_ item: HistoryItemDecorator) -> Int {
    var hasher = Hasher()
    item.hash(into: &hasher)
    return hasher.finalize()
  }

  private func historyItemDecorator(
    _ value: Data?,
    _ type: NSPasteboard.PasteboardType
  ) -> HistoryItemDecorator {
    let contents = [
      HistoryItemContent(
        type: type.rawValue,
        value: value
      )
    ]
    let item = HistoryItem()
    Storage.shared.context.insert(item)
    item.contents = contents
    item.title = item.generateTitle()
    item.application = "com.apple.finder"
    item.firstCopiedAt = firstCopiedAt
    item.lastCopiedAt = lastCopiedAt
    item.numberOfCopies = 2

    return HistoryItemDecorator(item)
  }

  private func historyItemDecorator(_ value: NSImage) -> HistoryItemDecorator {
    let contents = [
      HistoryItemContent(
        type: NSPasteboard.PasteboardType.tiff.rawValue,
        value: value.tiffRepresentation!
      )
    ]
    let item = HistoryItem()
    Storage.shared.context.insert(item)
    item.contents = contents
    item.title = item.generateTitle()
    item.application = "com.apple.finder"
    item.firstCopiedAt = firstCopiedAt
    item.lastCopiedAt = lastCopiedAt
    item.numberOfCopies = 2

    return HistoryItemDecorator(item)
  }

  private func historyItemDecorator(text: String, image: NSImage) -> HistoryItemDecorator {
    let contents = [
      HistoryItemContent(
        type: NSPasteboard.PasteboardType.string.rawValue,
        value: text.data(using: .utf8)
      ),
      HistoryItemContent(
        type: NSPasteboard.PasteboardType.tiff.rawValue,
        value: image.tiffRepresentation!
      )
    ]
    let item = HistoryItem()
    Storage.shared.context.insert(item)
    item.contents = contents
    item.title = item.generateTitle()
    item.application = "com.apple.finder"
    item.firstCopiedAt = firstCopiedAt
    item.lastCopiedAt = lastCopiedAt
    item.numberOfCopies = 2

    return HistoryItemDecorator(item)
  }

  private func historyItemDecorator(_ value: URL) -> HistoryItemDecorator {
    let contents = [
      HistoryItemContent(
        type: NSPasteboard.PasteboardType.fileURL.rawValue,
        value: value.dataRepresentation
      ),
      HistoryItemContent(
        type: NSPasteboard.PasteboardType.string.rawValue,
        value: value.lastPathComponent.data(using: .utf8)
      )
    ]
    let item = HistoryItem()
    Storage.shared.context.insert(item)
    item.contents = contents
    item.title = item.generateTitle()
    item.application = "com.apple.finder"
    item.firstCopiedAt = firstCopiedAt
    item.lastCopiedAt = lastCopiedAt
    item.numberOfCopies = 2

    return HistoryItemDecorator(item)
  }

  private func bitmapImage(width: Int, height: Int) throws -> NSImage {
    let bitmap = NSBitmapImageRep(
      bitmapDataPlanes: nil,
      pixelsWide: width,
      pixelsHigh: height,
      bitsPerSample: 8,
      samplesPerPixel: 4,
      hasAlpha: true,
      isPlanar: false,
      colorSpaceName: .deviceRGB,
      bitmapFormat: [.alphaFirst],
      bytesPerRow: 0,
      bitsPerPixel: 0
    )!

    let image = NSImage(size: NSSize(width: width, height: height))
    image.addRepresentation(bitmap)
    return image
  }

  // swiftlint:disable:next identifier_name
  private func range(from: Int, to: Int, in item: HistoryItemDecorator) -> Range<String.Index> {
    let startIndex = item.title.startIndex
    let lowerBound = item.title.index(startIndex, offsetBy: from)
    let upperBound = item.title.index(startIndex, offsetBy: to + 1)

    return lowerBound..<upperBound
  }
}
