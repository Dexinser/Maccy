enum IncrementalRenderWindow {
  static let initialLimit = 150
  static let batchSize = 150
  static let preloadThreshold = 20

  static func initialCount(total: Int) -> Int {
    min(total, initialLimit)
  }

  static func resetCount(total: Int) -> Int {
    initialCount(total: total)
  }

  static func expandedCount(total: Int, current: Int) -> Int {
    min(total, max(current, initialLimit) + batchSize)
  }

  static func countIncluding(index: Int, current: Int, total: Int) -> Int {
    guard total > current else { return total }
    guard index >= current - preloadThreshold else { return current }

    var count = current
    repeat {
      count = expandedCount(total: total, current: count)
    } while index >= count - preloadThreshold && count < total

    return count
  }
}
