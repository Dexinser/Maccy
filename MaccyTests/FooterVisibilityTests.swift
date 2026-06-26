import Defaults
import SwiftUI
import XCTest
@testable import Maccy

@MainActor
final class FooterVisibilityTests: XCTestCase {
  private var savedShowFooter = Defaults[.showFooter]

  override func tearDown() {
    Defaults[.showFooter] = savedShowFooter
    super.tearDown()
  }

  func testHiddenFooterHasNoVisibleItemsForNavigation() {
    Defaults[.showFooter] = false
    let footer = Footer()

    XCTAssertTrue(footer.visibleItems.isEmpty)
    XCTAssertNil(footer.firstVisibleItem)
    XCTAssertNil(footer.lastVisibleItem)
    XCTAssertNil(footer.visibleItem(after: footer.items[0]))
  }

  func testVisibleFooterExposesVisibleItemsForNavigation() {
    Defaults[.showFooter] = true
    let footer = Footer()

    XCTAssertEqual(footer.firstVisibleItem, footer.items[0])
    XCTAssertEqual(footer.visibleItem(after: footer.items[0]), footer.items[2])
    XCTAssertFalse(footer.items[1].isVisible)
  }

  func testFooterItemShowsConfirmationWhenActionIsNotSuppressed() {
    var suppressConfirmation = false
    var actionCalled = false
    let item = FooterItem(
      title: "clear",
      confirmation: .init(
        message: "message",
        comment: "comment",
        confirm: "confirm",
        cancel: "cancel"
      ),
      suppressConfirmation: Binding(
        get: { suppressConfirmation },
        set: { suppressConfirmation = $0 }
      )
    ) {
      actionCalled = true
    }

    item.performAction()

    XCTAssertTrue(item.showConfirmation)
    XCTAssertFalse(actionCalled)
  }

  func testFooterItemRunsActionWhenConfirmationIsSuppressed() {
    var suppressConfirmation = true
    var actionCalled = false
    let item = FooterItem(
      title: "clear",
      confirmation: .init(
        message: "message",
        comment: "comment",
        confirm: "confirm",
        cancel: "cancel"
      ),
      suppressConfirmation: Binding(
        get: { suppressConfirmation },
        set: { suppressConfirmation = $0 }
      )
    ) {
      actionCalled = true
    }

    item.performAction()

    XCTAssertFalse(item.showConfirmation)
    XCTAssertTrue(actionCalled)
  }
}
