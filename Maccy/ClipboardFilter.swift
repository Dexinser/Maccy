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
  case text
  case images
  case files

  var id: Self { self }

  var description: String {
    switch self {
    case .all:
      return "All"
    case .text:
      return "Text"
    case .images:
      return "Images"
    case .files:
      return "Files"
    }
  }

  func matches(_ kind: ClipboardItemKind) -> Bool {
    switch self {
    case .all:
      return true
    case .text:
      return kind == .text
    case .images:
      return kind == .image
    case .files:
      return kind == .file
    }
  }
}
