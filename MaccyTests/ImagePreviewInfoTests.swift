import AppKit
import XCTest
@testable import Maccy

final class ImagePreviewInfoTests: XCTestCase {
  @MainActor
  func testZoomWindowIsSizedInsideVisibleFrame() {
    let image = NSImage(size: NSSize(width: 2400, height: 1600))
    let visibleFrame = NSRect(x: 0, y: 0, width: 1000, height: 700)

    let frame = ImageZoomWindowController.windowFrame(for: image, visibleFrame: visibleFrame)

    XCTAssertLessThanOrEqual(frame.width, visibleFrame.width - 80)
    XCTAssertLessThanOrEqual(frame.height, visibleFrame.height - 80)
    XCTAssertGreaterThanOrEqual(frame.width, visibleFrame.width * 0.9)
    XCTAssertGreaterThanOrEqual(frame.height, visibleFrame.height * 0.85)
    XCTAssertGreaterThanOrEqual(frame.minX, visibleFrame.minX)
    XCTAssertGreaterThanOrEqual(frame.minY, visibleFrame.minY)
    XCTAssertLessThanOrEqual(frame.maxX, visibleFrame.maxX)
    XCTAssertLessThanOrEqual(frame.maxY, visibleFrame.maxY)
  }

  @MainActor
  func testZoomWindowUsesLargeInitialFrameForSmallImages() {
    let image = NSImage(size: NSSize(width: 320, height: 200))
    let visibleFrame = NSRect(x: 100, y: 200, width: 1440, height: 900)

    let frame = ImageZoomWindowController.windowFrame(for: image, visibleFrame: visibleFrame)

    XCTAssertGreaterThanOrEqual(frame.width, visibleFrame.width * 0.9)
    XCTAssertGreaterThanOrEqual(frame.height, visibleFrame.height * 0.85)
    XCTAssertGreaterThanOrEqual(frame.minX, visibleFrame.minX)
    XCTAssertGreaterThanOrEqual(frame.minY, visibleFrame.minY)
    XCTAssertLessThanOrEqual(frame.maxX, visibleFrame.maxX)
    XCTAssertLessThanOrEqual(frame.maxY, visibleFrame.maxY)
  }

  @MainActor
  func testZoomWindowHandlesTinyVisibleFrame() {
    let image = NSImage(size: NSSize(width: 2400, height: 1600))
    let visibleFrame = NSRect(x: 20, y: 30, width: 260, height: 180)

    let frame = ImageZoomWindowController.windowFrame(for: image, visibleFrame: visibleFrame)

    XCTAssertLessThanOrEqual(frame.width, visibleFrame.width)
    XCTAssertLessThanOrEqual(frame.height, visibleFrame.height)
    XCTAssertGreaterThanOrEqual(frame.minX, visibleFrame.minX)
    XCTAssertGreaterThanOrEqual(frame.minY, visibleFrame.minY)
    XCTAssertLessThanOrEqual(frame.maxX, visibleFrame.maxX)
    XCTAssertLessThanOrEqual(frame.maxY, visibleFrame.maxY)
  }

  @MainActor
  func testZoomedImageFrameIsClampedToSafeMaximum() {
    let image = NSImage(size: NSSize(width: 2048, height: 1536))

    let frameSize = ImageZoomWindowController.imageFrameSize(for: image, scale: 6)

    XCTAssertLessThanOrEqual(frameSize.width, 4096)
    XCTAssertLessThanOrEqual(frameSize.height, 4096)
  }

  @MainActor
  func testImageDragScrollOriginMovesOppositeDragDirection() {
    let origin = ImageZoomScrollView.scrolledOrigin(
      currentOrigin: NSPoint(x: 300, y: 400),
      dragDelta: NSPoint(x: 40, y: -25),
      contentSize: NSSize(width: 1200, height: 1000),
      viewportSize: NSSize(width: 500, height: 400)
    )

    XCTAssertEqual(origin.x, 260)
    XCTAssertEqual(origin.y, 425)
  }

  @MainActor
  func testImageDragScrollOriginIsClampedToScrollableBounds() {
    let origin = ImageZoomScrollView.scrolledOrigin(
      currentOrigin: NSPoint(x: 10, y: 20),
      dragDelta: NSPoint(x: 200, y: 300),
      contentSize: NSSize(width: 1200, height: 1000),
      viewportSize: NSSize(width: 500, height: 400)
    )

    XCTAssertEqual(origin.x, 0)
    XCTAssertEqual(origin.y, 0)
  }

  @MainActor
  func testZoomWindowKeepsControllerAliveUntilClose() {
    let controller = ImageZoomWindowController.show(
      image: NSImage(size: NSSize(width: 32, height: 32)),
      title: "Preview",
      owner: nil,
      visibleFrame: NSRect(x: 0, y: 0, width: 800, height: 600)
    )

    XCTAssertTrue(controller.window?.isVisible == true)

    controller.close()

    XCTAssertTrue(controller.isReleasedAfterClose)
  }

  @MainActor
  func testZoomWindowKeepsLargeFrameAfterShowWindow() {
    let visibleFrame = NSRect(x: 0, y: 0, width: 1440, height: 900)
    let controller = ImageZoomWindowController.show(
      image: NSImage(size: NSSize(width: 64, height: 64)),
      title: "Preview",
      owner: nil,
      visibleFrame: visibleFrame
    )

    guard let frame = controller.window?.frame else {
      XCTFail("Expected zoom window to exist")
      return
    }

    controller.window?.contentView?.layoutSubtreeIfNeeded()
    RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.05))

    guard let frameAfterLayout = controller.window?.frame else {
      XCTFail("Expected zoom window to remain open")
      return
    }

    XCTAssertGreaterThanOrEqual(frame.width, visibleFrame.width * 0.9)
    XCTAssertGreaterThanOrEqual(frame.height, visibleFrame.height * 0.85)
    XCTAssertGreaterThanOrEqual(frameAfterLayout.width, visibleFrame.width * 0.9)
    XCTAssertGreaterThanOrEqual(frameAfterLayout.height, visibleFrame.height * 0.85)

    controller.close()
  }

  @MainActor
  func testZoomWindowReleasesControllerWhenWindowCloses() {
    let controller = ImageZoomWindowController.show(
      image: NSImage(size: NSSize(width: 32, height: 32)),
      title: "Preview",
      owner: nil,
      visibleFrame: NSRect(x: 0, y: 0, width: 800, height: 600)
    )

    controller.window?.close()

    XCTAssertTrue(controller.isReleasedAfterClose)
  }

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
