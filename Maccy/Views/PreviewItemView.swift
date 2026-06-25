import KeyboardShortcuts
import SwiftUI

private func previewString(_ key: String, defaultValue: String) -> String {
  NSLocalizedString(key, tableName: "PreviewItemView", value: defaultValue, comment: "")
}

private struct PreviewActionButton: View {
  let systemName: String
  let help: String
  let action: @MainActor () -> Void

  var body: some View {
    Button(action: action) {
      Image(systemName: systemName)
        .frame(width: 22, height: 22)
    }
    .buttonStyle(.borderless)
    .help(Text(help))
  }
}

struct PreviewItemView: View {
  var item: HistoryItemDecorator

  @State private var textSelection = PreviewTextSelection()

  @ViewBuilder
  func previewImage(content: () -> some View) -> some View {
    content()
      .aspectRatio(contentMode: .fit)
      .clipShape(.rect(cornerRadius: 5))
  }

  @ViewBuilder
  private var previewContent: some View {
    if item.hasImage {
      AsyncView<NSImage?, _, _> {
        return await item.asyncGetPreviewImage()
      } content: { image in
        if let image = image {
          previewImage {
            Image(nsImage: image)
              .resizable()
          }
        } else {
          previewImage {
            ZStack {
              Color.gray.opacity(0.3)
                .frame(
                  idealWidth: HistoryItemDecorator.previewImageSize.width,
                  idealHeight: HistoryItemDecorator.previewImageSize.height
                )
              Image(systemName: "photo.badge.exclamationmark")
                .symbolRenderingMode(.multicolor)
                .frame(alignment: .center)
            }
          }
        }
      } placeholder: {
        previewImage {
          ZStack {
            Color.gray.opacity(0.3)
              .frame(
                idealWidth: HistoryItemDecorator.previewImageSize.width,
                idealHeight: HistoryItemDecorator.previewImageSize.height
              )
            ProgressView()
              .frame(alignment: .center)
          }
        }
      }
    } else {
      SelectableTextPreviewView(text: item.text, selection: textSelection)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .textBackgroundColor).opacity(0.35))
        .clipShape(.rect(cornerRadius: 5))
        .overlay {
          RoundedRectangle(cornerRadius: 5)
            .stroke(Color(nsColor: .separatorColor).opacity(0.6), lineWidth: 1)
        }
    }
  }

  private var textActions: some View {
    HStack(spacing: 8) {
      PreviewActionButton(
        systemName: "text.quote",
        help: previewString("CopySelection", defaultValue: "Copy selection")
      ) {
        Clipboard.shared.copy(textSelection.textForCopy)
      }
      .disabled(!textSelection.canCopySelection)

      PreviewActionButton(
        systemName: "doc.text",
        help: previewString("CopyAllText", defaultValue: "Copy preview text")
      ) {
        Clipboard.shared.copy(item.text)
      }

      PreviewActionButton(
        systemName: "doc.on.doc",
        help: previewString("CopyItem", defaultValue: "Copy original item")
      ) {
        Clipboard.shared.copy(item.item)
      }

      Spacer(minLength: 0)
    }
  }

  @ViewBuilder
  private var actionBar: some View {
    if !item.hasImage {
      textActions
    } else {
      HStack {
        PreviewActionButton(
          systemName: "doc.on.doc",
          help: previewString("CopyItem", defaultValue: "Copy original item")
        ) {
          Clipboard.shared.copy(item.item)
        }

        Spacer(minLength: 0)
      }
    }
  }

  private var metadata: some View {
    VStack(alignment: .leading, spacing: 4) {
      if let application = item.application {
        HStack(spacing: 3) {
          Text("Application", tableName: "PreviewItemView")
          AppImageView(
            appImage: item.applicationImage,
            size: NSSize(width: 11, height: 11)
          )
          Text(application)
        }
      }

      HStack(spacing: 3) {
        Text("FirstCopyTime", tableName: "PreviewItemView")
        Text(item.item.firstCopiedAt, style: .date)
        Text(item.item.firstCopiedAt, style: .time)
      }

      HStack(spacing: 3) {
        Text("LastCopyTime", tableName: "PreviewItemView")
        Text(item.item.lastCopiedAt, style: .date)
        Text(item.item.lastCopiedAt, style: .time)
      }

      HStack(spacing: 3) {
        Text("NumberOfCopies", tableName: "PreviewItemView")
        Text(String(item.item.numberOfCopies))
      }
    }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      previewContent

      Spacer(minLength: 0)

      actionBar

      Divider()

      metadata
    }
    .controlSize(.small)
    .task(id: item.id) {
      textSelection.reset()
    }
  }
}
