import SwiftUI

struct FilePreviewDetailView: View {
  let item: HistoryItemDecorator
  let info: FilePreviewInfo

  private var canOpenFile: Bool {
    info.exists
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(alignment: .center, spacing: 12) {
        Image(nsImage: info.icon)
          .resizable()
          .frame(width: 48, height: 48)

        VStack(alignment: .leading, spacing: 3) {
          Text(info.name)
            .font(.headline)
            .lineLimit(2)
          Text(info.path)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(3)
            .textSelection(.enabled)
        }
      }

      HStack(spacing: 8) {
        PreviewActionButton(
          systemName: "doc.on.doc",
          help: previewString("CopyItem", defaultValue: "Copy original item")
        ) {
          Clipboard.shared.copy(item.item)
        }

        PreviewActionButton(
          systemName: "arrow.up.forward.app",
          help: previewString("OpenFile", defaultValue: "Open file")
        ) {
          NSWorkspace.shared.open(info.url)
        }
        .disabled(!canOpenFile)

        PreviewActionButton(
          systemName: "folder",
          help: previewString("RevealInFinder", defaultValue: "Reveal in Finder")
        ) {
          NSWorkspace.shared.activateFileViewerSelecting([info.url])
        }
        .disabled(!canOpenFile)

        Spacer(minLength: 0)
      }

      VStack(alignment: .leading, spacing: 5) {
        if info.exists {
          if !info.formattedSize.isEmpty {
            metadataRow("FileSize", value: info.formattedSize)
          }

          if !info.kind.isEmpty {
            metadataRow("FileKind", value: info.kind)
          }

          if let modifiedAt = info.modifiedAt {
            HStack(spacing: 4) {
              Text("ModifiedTime", tableName: "PreviewItemView")
              Text(modifiedAt, style: .date)
              Text(modifiedAt, style: .time)
            }
          }
        } else {
          Text("FileUnavailable", tableName: "PreviewItemView")
            .foregroundStyle(.secondary)
        }
      }
      .font(.caption)

      Spacer(minLength: 0)
    }
  }

  private func metadataRow(_ key: LocalizedStringKey, value: String) -> some View {
    HStack(spacing: 4) {
      Text(key, tableName: "PreviewItemView")
      Text(value)
    }
  }
}
