import XCTest
@testable import Maccy

final class IncrementalRenderWindowTests: XCTestCase {
  func testInitialCountCapsLargeLists() {
    XCTAssertEqual(IncrementalRenderWindow.initialCount(total: 20), 20)
    XCTAssertEqual(IncrementalRenderWindow.initialCount(total: 500), IncrementalRenderWindow.initialLimit)
  }

  func testExpandedCountLoadsOneBatchWithoutExceedingTotal() {
    XCTAssertEqual(
      IncrementalRenderWindow.expandedCount(total: 500, current: IncrementalRenderWindow.initialLimit),
      IncrementalRenderWindow.initialLimit + IncrementalRenderWindow.batchSize
    )
    XCTAssertEqual(IncrementalRenderWindow.expandedCount(total: 175, current: 150), 175)
  }

  func testCountIncludingIndexExpandsWhenSelectionApproachesRenderedTail() {
    XCTAssertEqual(
      IncrementalRenderWindow.countIncluding(index: 10, current: 150, total: 500),
      150
    )
    XCTAssertEqual(
      IncrementalRenderWindow.countIncluding(index: 145, current: 150, total: 500),
      300
    )
    XCTAssertEqual(
      IncrementalRenderWindow.countIncluding(index: 420, current: 300, total: 500),
      450
    )
  }

  func testResetShrinksBackToInitialCountForNewResultSet() {
    XCTAssertEqual(IncrementalRenderWindow.resetCount(total: 500), IncrementalRenderWindow.initialLimit)
    XCTAssertEqual(IncrementalRenderWindow.resetCount(total: 80), 80)
  }
}
