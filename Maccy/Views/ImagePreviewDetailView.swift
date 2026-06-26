import SwiftUI

struct ImagePreviewDetailView: View {
  let item: HistoryItemDecorator
  @State private var currentItemID: UUID
  @State private var zoomTask: Task<Void, Never>?

  init(item: HistoryItemDecorator) {
    self.item = item
    _currentItemID = State(initialValue: item.id)
  }

  private var info: ImagePreviewInfo {
    ImagePreviewInfo(data: item.item.imageData)
  }

  private func previewImage(content: () -> some View) -> some View {
    content()
      .aspectRatio(contentMode: .fit)
      .clipShape(.rect(cornerRadius: 5))
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      AsyncView<NSImage?, _, _>(id: item.id) {
        return await item.asyncGetPreviewImage()
      } content: { image in
        if let image = image {
          previewImage {
            Image(nsImage: image)
              .resizable()
          }
          .onTapGesture {
            guard currentItemID == item.id else { return }
            _ = ImageZoomWindowController.show(
              image: image,
              title: item.title,
              owner: AppState.shared.appDelegate?.panel
            )
          }
        } else {
          unavailableImage
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

      HStack(spacing: 8) {
        PreviewActionButton(
          systemName: "doc.on.doc",
          help: previewString("CopyItem", defaultValue: "Copy original item")
        ) {
          Clipboard.shared.copy(item.item)
        }

        PreviewActionButton(
          systemName: "magnifyingglass",
          help: previewString("ZoomImage", defaultValue: "Zoom image")
        ) {
          let requestedItemID = item.id
          zoomTask?.cancel()
          zoomTask = Task { @MainActor in
            guard let previewImage = await item.asyncGetPreviewImage(),
                  !Task.isCancelled,
                  currentItemID == requestedItemID
            else { return }

            _ = ImageZoomWindowController.show(
              image: previewImage,
              title: item.title,
              owner: AppState.shared.appDelegate?.panel
            )
          }
        }

        Spacer(minLength: 0)
      }

      VStack(alignment: .leading, spacing: 4) {
        if let dimensions = info.dimensions {
          metadataRow("ImageDimensions", value: dimensions)
        }

        if !info.formattedDataSize.isEmpty {
          metadataRow("DataSize", value: info.formattedDataSize)
        }
      }
      .font(.caption)
      .foregroundStyle(.secondary)
    }
    .onChange(of: item.id) {
      zoomTask?.cancel()
      zoomTask = nil
      currentItemID = item.id
    }
    .onDisappear {
      zoomTask?.cancel()
      zoomTask = nil
    }
  }

  private var unavailableImage: some View {
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

  private func metadataRow(_ key: LocalizedStringKey, value: String) -> some View {
    HStack(spacing: 4) {
      Text(key, tableName: "PreviewItemView")
      Text(value)
    }
  }
}
