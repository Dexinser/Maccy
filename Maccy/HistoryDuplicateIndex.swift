import CryptoKit
import Foundation

struct HistoryItemContentSignature: Hashable {
  let type: String
  let valueDigest: Data

  init?(_ content: HistoryItemContent) {
    guard !HistoryItem.isTransientContentType(content.type) else {
      return nil
    }

    var payload = Data()
    payload.append(content.value == nil ? 0 : 1)
    if let value = content.value {
      payload.append(value)
    }

    type = content.type
    valueDigest = Data(SHA256.hash(data: payload))
  }
}

struct HistoryDuplicateIndex {
  private var itemsBySignature: [HistoryItemContentSignature: [HistoryItemDecorator]] = [:]
  private var orderByObject: [ObjectIdentifier: Int] = [:]
  private var signaturesByObject: [ObjectIdentifier: Set<HistoryItemContentSignature>] = [:]

  init(items: [HistoryItemDecorator] = []) {
    rebuild(with: items)
  }

  mutating func rebuild(with items: [HistoryItemDecorator]) {
    itemsBySignature = [:]
    orderByObject = [:]
    signaturesByObject = [:]

    for (index, item) in items.enumerated() {
      insert(item, at: index)
    }
  }

  mutating func insert(_ item: HistoryItemDecorator, at index: Int) {
    remove(item)

    let insertionIndex = max(0, min(index, orderByObject.count))
    shiftOrders(startingAt: insertionIndex, by: 1)

    let object = ObjectIdentifier(item.item)
    let signatures = Set(item.item.comparableContentSignatures)
    orderByObject[object] = insertionIndex
    signaturesByObject[object] = signatures

    for signature in signatures {
      itemsBySignature[signature, default: []].append(item)
    }
  }

  mutating func remove(_ item: HistoryItemDecorator) {
    let object = ObjectIdentifier(item.item)
    guard let removedIndex = orderByObject.removeValue(forKey: object) else {
      return
    }

    let signatures = signaturesByObject.removeValue(forKey: object) ?? []
    for signature in signatures {
      guard var items = itemsBySignature[signature] else {
        continue
      }
      items.removeAll { ObjectIdentifier($0.item) == object }
      if items.isEmpty {
        itemsBySignature.removeValue(forKey: signature)
      } else {
        itemsBySignature[signature] = items
      }
    }

    shiftOrders(startingAt: removedIndex + 1, by: -1)
  }

  mutating func reorder(with items: [HistoryItemDecorator]) {
    orderByObject = Dictionary(uniqueKeysWithValues: items.enumerated().map { index, item in
      (ObjectIdentifier(item.item), index)
    })
  }

  func candidates(for item: HistoryItem) -> [HistoryItem] {
    let signatures = Set(item.comparableContentSignatures)
    guard !signatures.isEmpty else {
      return []
    }

    var candidatesByObject: [ObjectIdentifier: HistoryItemDecorator] = [:]
    for signature in signatures {
      for candidate in itemsBySignature[signature, default: []] {
        candidatesByObject[ObjectIdentifier(candidate.item)] = candidate
      }
    }

    return candidatesByObject.values
      .sorted {
        (orderByObject[ObjectIdentifier($0.item)] ?? Int.max) <
          (orderByObject[ObjectIdentifier($1.item)] ?? Int.max)
      }
      .map(\.item)
  }

  private mutating func shiftOrders(startingAt index: Int, by delta: Int) {
    let objects = orderByObject
      .filter { $0.value >= index }
      .map(\.key)

    for object in objects {
      if let order = orderByObject[object] {
        orderByObject[object] = order + delta
      }
    }
  }
}
