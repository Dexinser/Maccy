import AppKit
import Foundation

struct FilePreviewInfo {
  let url: URL
  let name: String
  let path: String
  let exists: Bool
  let byteCount: Int64?
  let formattedSize: String
  let kind: String
  let modifiedAt: Date?

  init(url: URL, fileManager: FileManager = .default) {
    self.url = url
    name = url.lastPathComponent
    path = url.path
    exists = fileManager.fileExists(atPath: url.path)

    let resourceValues = try? url.resourceValues(forKeys: [
      .contentModificationDateKey,
      .fileSizeKey,
      .localizedTypeDescriptionKey,
      .totalFileSizeKey
    ])

    modifiedAt = exists ? resourceValues?.contentModificationDate : nil

    if exists {
      if let fileSize = resourceValues?.fileSize {
        byteCount = Int64(fileSize)
      } else if let totalFileSize = resourceValues?.totalFileSize {
        byteCount = Int64(totalFileSize)
      } else {
        byteCount = nil
      }
    } else {
      byteCount = nil
    }

    if let byteCount {
      formattedSize = ByteCountFormatter.string(fromByteCount: byteCount, countStyle: .file)
    } else {
      formattedSize = ""
    }

    kind = resourceValues?.localizedTypeDescription ?? ""
  }

  var icon: NSImage {
    NSWorkspace.shared.icon(forFile: path)
  }
}
