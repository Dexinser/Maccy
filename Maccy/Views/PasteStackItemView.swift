import Defaults
import SwiftUI

private struct PasteStackId: Hashable {
  var pasteStackId: UUID
  var itemId: UUID

  static func == (lhs: PasteStackId, rhs: PasteStackId) -> Bool {
    return lhs.pasteStackId == rhs.pasteStackId && lhs.itemId == rhs.itemId
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(pasteStackId)
    hasher.combine(itemId)
  }
}

struct PasteStackItemPresentation {
  let title: String
  let thumbnailImage: NSImage?
  let accessoryImage: NSImage?
  let attributedTitle: AttributedString?
  let showsTitle: Bool

  init(item: HistoryItemDecorator, index: Int?) {
    title = item.listTitle
    thumbnailImage = index != nil ? item.thumbnailImage : nil
    accessoryImage = thumbnailImage == nil ? item.listAccessoryImage : nil
    attributedTitle = item.listAttributedTitle
    showsTitle = item.showsListTitle
  }
}

struct PasteStackItemView: View {
  var stack: PasteStack
  var item: HistoryItemDecorator
  var index: Int?
  var isSelected: Bool

  var body: some View {
    let presentation = PasteStackItemPresentation(item: item, index: index)

    ListItemView(
      id: PasteStackId(pasteStackId: stack.id, itemId: item.id),
      selectionId: stack.id,
      appIcon: item.applicationImage,
      image: presentation.thumbnailImage,
      accessoryImage: presentation.accessoryImage,
      attributedTitle: presentation.attributedTitle,
      shortcuts: [],
      isSelected: isSelected,
      selectionIndex: index,
      showsTitle: presentation.showsTitle,
      selectionAppearance: .none
    ) {
      Text(verbatim: presentation.title)
    }
  }
}
