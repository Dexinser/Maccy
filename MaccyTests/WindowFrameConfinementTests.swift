import XCTest
@testable import Maccy

final class WindowFrameConfinementTests: XCTestCase {
  func testChoosesVisibleFrameContainingProposedFrameCenter() {
    let leftScreen = NSRect(x: -1440, y: 0, width: 1440, height: 900)
    let rightScreen = NSRect(x: 0, y: 0, width: 1920, height: 1080)
    let proposedFrame = NSRect(x: 40, y: 100, width: 600, height: 500)

    let visibleFrame = WindowFrameConfinement.visibleFrame(
      for: proposedFrame,
      in: [leftScreen, rightScreen]
    )

    XCTAssertEqual(visibleFrame, rightScreen)
  }

  func testChoosesVisibleFrameWithLargestOverlapWhenCenterIsOutsideScreens() {
    let leftScreen = NSRect(x: -1440, y: 0, width: 1440, height: 900)
    let rightScreen = NSRect(x: 0, y: 0, width: 1920, height: 1080)
    let proposedFrame = NSRect(x: 1600, y: 100, width: 600, height: 500)

    let visibleFrame = WindowFrameConfinement.visibleFrame(
      for: proposedFrame,
      in: [leftScreen, rightScreen]
    )

    XCTAssertEqual(visibleFrame, rightScreen)
  }

  func testConfinesFrameInsideVisibleFrame() {
    let visibleFrame = NSRect(x: 100, y: 80, width: 500, height: 300)
    let offscreenFrame = NSRect(x: 40, y: -20, width: 700, height: 400)

    let confinedFrame = WindowFrameConfinement.confine(frame: offscreenFrame, to: visibleFrame)

    XCTAssertEqual(confinedFrame, visibleFrame)
  }

  func testKeepsVisibleFrameUnchanged() {
    let visibleFrame = NSRect(x: 100, y: 80, width: 500, height: 300)
    let frame = NSRect(x: 150, y: 120, width: 300, height: 200)

    let confinedFrame = WindowFrameConfinement.confine(frame: frame, to: visibleFrame)

    XCTAssertEqual(confinedFrame, frame)
  }

  func testMovesFrameBackFromRightAndTopEdges() {
    let visibleFrame = NSRect(x: 100, y: 80, width: 500, height: 300)
    let offscreenFrame = NSRect(x: 450, y: 300, width: 200, height: 120)

    let confinedFrame = WindowFrameConfinement.confine(frame: offscreenFrame, to: visibleFrame)

    XCTAssertEqual(confinedFrame.origin.x, 400)
    XCTAssertEqual(confinedFrame.origin.y, 260)
    XCTAssertEqual(confinedFrame.size, offscreenFrame.size)
  }

  func testConfinesFrameToSelectedTargetVisibleFrame() throws {
    let leftScreen = NSRect(x: -1440, y: 0, width: 1440, height: 900)
    let rightScreen = NSRect(x: 0, y: 0, width: 1920, height: 1080)
    let proposedFrame = NSRect(x: 1820, y: 900, width: 500, height: 300)

    let visibleFrame = try XCTUnwrap(WindowFrameConfinement.visibleFrame(
      for: proposedFrame,
      in: [leftScreen, rightScreen]
    ))
    let confinedFrame = WindowFrameConfinement.confine(frame: proposedFrame, to: visibleFrame)

    XCTAssertEqual(confinedFrame, NSRect(x: 1420, y: 780, width: 500, height: 300))
  }

  func testConfinesFrameUsingTargetVisibleFrameList() {
    let leftScreen = NSRect(x: -1440, y: 0, width: 1440, height: 900)
    let rightScreen = NSRect(x: 0, y: 0, width: 1920, height: 1080)
    let proposedFrame = NSRect(x: 1820, y: 900, width: 500, height: 300)

    let confinedFrame = WindowFrameConfinement.confine(
      frame: proposedFrame,
      in: [leftScreen, rightScreen]
    )

    XCTAssertEqual(confinedFrame, NSRect(x: 1420, y: 780, width: 500, height: 300))
  }
}
