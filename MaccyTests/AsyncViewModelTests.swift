import XCTest
@testable import Maccy

@MainActor
final class AsyncViewModelTests: XCTestCase {
  func testIgnoresOutdatedResultAfterIdentityChanges() async {
    let firstValueStarted = expectation(description: "first value started")
    let firstValueCanFinish = expectation(description: "first value can finish")
    let secondValueLoaded = expectation(description: "second value loaded")
    let firstValueFinished = expectation(description: "first value finished")
    let model = AsyncViewModel<Int, Int>()

    await model.load(id: 1) {
      firstValueStarted.fulfill()
      await self.fulfillment(of: [firstValueCanFinish])
      firstValueFinished.fulfill()
      return 1
    }

    await fulfillment(of: [firstValueStarted])

    await model.load(id: 2) {
      secondValueLoaded.fulfill()
      return 2
    }

    await fulfillment(of: [secondValueLoaded])
    XCTAssertEqual(model.loadedValue, 2)

    firstValueCanFinish.fulfill()
    await fulfillment(of: [firstValueFinished])
    XCTAssertEqual(model.loadedValue, 2)
  }
}
