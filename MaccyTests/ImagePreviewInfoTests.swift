import AppKit
import XCTest
@testable import Maccy

final class ImagePreviewInfoTests: XCTestCase {
  func testImageMetadataUsesPixelDimensionsAndDataSize() throws {
    let data = try pngData(width: 3, height: 2)

    let info = ImagePreviewInfo(data: data)

    XCTAssertEqual(info.pixelWidth, 3)
    XCTAssertEqual(info.pixelHeight, 2)
    XCTAssertEqual(info.dimensions, "3 x 2 px")
    XCTAssertEqual(info.byteCount, data.count)
    XCTAssertFalse(info.formattedDataSize.isEmpty)
  }

  func testMissingImageDataDoesNotCrash() {
    let info = ImagePreviewInfo(data: nil)

    XCTAssertNil(info.pixelWidth)
    XCTAssertNil(info.pixelHeight)
    XCTAssertNil(info.dimensions)
    XCTAssertNil(info.byteCount)
    XCTAssertEqual(info.formattedDataSize, "")
  }

  private func pngData(width: Int, height: Int) throws -> Data {
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

    bitmap.size = NSSize(width: width, height: height)

    guard let data = bitmap.representation(using: .png, properties: [:]) else {
      throw XCTSkip("Unable to create PNG fixture data")
    }

    return data
  }
}
