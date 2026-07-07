import AppKit
import Defaults

// swiftlint:disable identifier_name
// swiftlint:disable type_name
class Sorter {
  enum By: String, CaseIterable, Identifiable, CustomStringConvertible, Defaults.Serializable {
    case lastCopiedAt
    case firstCopiedAt
    case numberOfCopies

    var id: Self { self }

    var description: String {
      switch self {
      case .lastCopiedAt:
        return NSLocalizedString("LastCopiedAt", tableName: "StorageSettings", comment: "")
      case .firstCopiedAt:
        return NSLocalizedString("FirstCopiedAt", tableName: "StorageSettings", comment: "")
      case .numberOfCopies:
        return NSLocalizedString("NumberOfCopies", tableName: "StorageSettings", comment: "")
      }
    }
  }

  func sort(_ items: [HistoryItem], by: By = Defaults[.sortBy]) -> [HistoryItem] {
    return items.sorted { shouldSort($0, before: $1, by: by) }
  }

  func sort(_ items: [HistoryItemDecorator], by: By = Defaults[.sortBy]) -> [HistoryItemDecorator] {
    return items.sorted { shouldSort($0.item, before: $1.item, by: by) }
  }

  func insertionIndex(
    for item: HistoryItem,
    in sortedItems: [HistoryItem],
    by: By = Defaults[.sortBy]
  ) -> Int {
    sortedItems.firstIndex { shouldSort(item, before: $0, by: by) } ?? sortedItems.endIndex
  }

  func insertionIndex(
    for item: HistoryItem,
    in sortedItems: [HistoryItemDecorator],
    by: By = Defaults[.sortBy]
  ) -> Int {
    sortedItems.firstIndex { shouldSort(item, before: $0.item, by: by) } ?? sortedItems.endIndex
  }

  private func shouldSort(_ lhs: HistoryItem, before rhs: HistoryItem, by: By) -> Bool {
    if (lhs.pin == nil) != (rhs.pin == nil) {
      return byPinned(lhs, rhs)
    }

    return bySortingAlgorithm(lhs, rhs, by)
  }

  private func bySortingAlgorithm(_ lhs: HistoryItem, _ rhs: HistoryItem, _ by: By) -> Bool {
    switch by {
    case .firstCopiedAt:
      return lhs.firstCopiedAt > rhs.firstCopiedAt
    case .numberOfCopies:
      return lhs.numberOfCopies > rhs.numberOfCopies
    default:
      return lhs.lastCopiedAt > rhs.lastCopiedAt
    }
  }

  private func byPinned(_ lhs: HistoryItem, _ rhs: HistoryItem) -> Bool {
    if Defaults[.pinTo] == .bottom {
      return (lhs.pin == nil) && (rhs.pin != nil)
    } else {
      return (lhs.pin != nil) && (rhs.pin == nil)
    }
  }
}
// swiftlint:enable identifier_name
// swiftlint:enable type_name
