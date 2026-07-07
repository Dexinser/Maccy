import Defaults
import Foundation

enum ClipboardItemKind: String, CaseIterable, Identifiable, CustomStringConvertible, Defaults.Serializable {
  case text
  case image
  case file
  case mixed

  var id: Self { self }

  var description: String {
    switch self {
    case .text:
      return "Text"
    case .image:
      return "Image"
    case .file:
      return "File"
    case .mixed:
      return "Mixed"
    }
  }
}

enum ClipboardFilter: String, CaseIterable, Identifiable, CustomStringConvertible, Defaults.Serializable {
  case all
  case favorites
  case text
  case images
  case files

  var id: Self { self }

  var description: String {
    switch self {
    case .all:
      return "All"
    case .favorites:
      return "Favorites"
    case .text:
      return "Text"
    case .images:
      return "Images"
    case .files:
      return "Files"
    }
  }

  func matches(_ item: some ClipboardItemMatching) -> Bool {
    switch self {
    case .all:
      return true
    case .favorites:
      return item.isFavorite
    case .text:
      return item.containsText
    case .images:
      return item.containsImage
    case .files:
      return item.containsFiles
    }
  }

}

protocol ClipboardItemMatching {
  var isFavorite: Bool { get }
  var containsText: Bool { get }
  var containsImage: Bool { get }
  var containsFiles: Bool { get }
}
