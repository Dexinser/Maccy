import XCTest
@testable import Maccy

final class FilePreviewInfoTests: XCTestCase {
  func testExistingFileMetadata() throws {
    let url = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)
      .appendingPathExtension("txt")
    let data = Data("hello".utf8)
    try data.write(to: url)
    defer { try? FileManager.default.removeItem(at: url) }

    let info = FilePreviewInfo(url: url)

    XCTAssertEqual(info.name, url.lastPathComponent)
    XCTAssertEqual(info.path, url.path)
    XCTAssertTrue(info.exists)
    XCTAssertEqual(info.byteCount, Int64(data.count))
    XCTAssertFalse(info.formattedSize.isEmpty)
    XCTAssertNotNil(info.modifiedAt)
    XCTAssertFalse(info.kind.isEmpty)
  }

  func testMissingFileMetadataDoesNotCrash() {
    let url = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)
      .appendingPathExtension("missing")

    let info = FilePreviewInfo(url: url)

    XCTAssertEqual(info.name, url.lastPathComponent)
    XCTAssertEqual(info.path, url.path)
    XCTAssertFalse(info.exists)
    XCTAssertNil(info.byteCount)
    XCTAssertNil(info.modifiedAt)
    XCTAssertEqual(info.formattedSize, "")
  }
}
