import AppKit
import SwiftUI

@MainActor
final class ImageZoomWindowController: NSWindowController, NSWindowDelegate {
  private static var activeController: ImageZoomWindowController?
  private static let screenMargin: CGFloat = 40
  private static let toolbarHeight: CGFloat = 52
  private static let imagePadding: CGFloat = 32
  private static let preferredVisibleFrameWidthRatio: CGFloat = 0.92
  private static let preferredVisibleFrameHeightRatio: CGFloat = 0.88
  private static let maximumZoomedImageDimension: CGFloat = 4096
  private static let minimumWindowSize = NSSize(width: 520, height: 420)

  private let initialFrame: NSRect

  var isReleasedAfterClose: Bool {
    return Self.activeController !== self
  }

  static func show(
    image: NSImage,
    title: String,
    owner: NSWindow?,
    visibleFrame: NSRect? = nil
  ) -> ImageZoomWindowController {
    activeController?.close()

    let visibleFrame = visibleFrame
      ?? owner?.screen?.visibleFrame
      ?? NSScreen.main?.visibleFrame
      ?? NSRect(x: 0, y: 0, width: 1024, height: 768)
    let controller = ImageZoomWindowController(
      image: image,
      title: title,
      frame: windowFrame(for: image, visibleFrame: visibleFrame),
      owner: owner
    )
    activeController = controller
    controller.showWindow(nil)
    controller.applyInitialFrame(display: true)
    controller.window?.orderFrontRegardless()

    return controller
  }

  static func windowFrame(for image: NSImage, visibleFrame: NSRect) -> NSRect {
    let maxSize = NSSize(
      width: max(minimumWindowSize.width, visibleFrame.width - screenMargin * 2),
      height: max(minimumWindowSize.height, visibleFrame.height - screenMargin * 2)
    )
    let preferredSize = NSSize(
      width: min(maxSize.width, max(minimumWindowSize.width, visibleFrame.width * preferredVisibleFrameWidthRatio)),
      height: min(maxSize.height, max(minimumWindowSize.height, visibleFrame.height * preferredVisibleFrameHeightRatio))
    )
    let centeredFrame = NSRect.centered(ofSize: preferredSize, in: visibleFrame)

    return WindowFrameConfinement.confine(frame: centeredFrame, to: visibleFrame)
  }

  static func imageFrameSize(for image: NSImage, scale: CGFloat) -> NSSize {
    let requestedSize = NSSize(
      width: max(1, image.size.width * scale),
      height: max(1, image.size.height * scale)
    )
    guard requestedSize.width > maximumZoomedImageDimension
      || requestedSize.height > maximumZoomedImageDimension
    else {
      return requestedSize
    }

    let ratio = min(
      maximumZoomedImageDimension / requestedSize.width,
      maximumZoomedImageDimension / requestedSize.height
    )
    return NSSize(
      width: max(1, requestedSize.width * ratio),
      height: max(1, requestedSize.height * ratio)
    )
  }

  private init(image: NSImage, title: String, frame: NSRect, owner: NSWindow?) {
    initialFrame = frame

    let window = NSWindow(
      contentRect: frame,
      styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
      backing: .buffered,
      defer: false
    )
    window.title = title.isEmpty ? previewString("ZoomImage", defaultValue: "Zoom image") : title
    window.titlebarAppearsTransparent = false
    window.isReleasedWhenClosed = false
    window.level = .floating
    window.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
    window.setFrame(frame, display: false)

    super.init(window: window)

    window.delegate = self
    let hostingController = NSHostingController(
      rootView: ImageZoomView(image: image) { [weak self] in
        self?.close()
      }
    )
    hostingController.sizingOptions = []
    window.contentViewController = hostingController

    if owner?.isVisible == true {
      window.level = max(owner?.level ?? .normal, .floating)
    }

    applyInitialFrame(display: false)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func windowWillClose(_ notification: Notification) {
    if Self.activeController === self {
      Self.activeController = nil
    }
  }

  private func applyInitialFrame(display: Bool) {
    guard let window else { return }

    window.setFrame(initialFrame, display: display)
    window.contentViewController?.view.frame = NSRect(
      origin: .zero,
      size: window.contentView?.bounds.size ?? initialFrame.size
    )
  }
}

private struct ImageZoomView: View {
  let image: NSImage
  let onClose: () -> Void

  @State private var scale: CGFloat = 1

  var body: some View {
    VStack(spacing: 0) {
      HStack(spacing: 8) {
        PreviewActionButton(
          systemName: "minus.magnifyingglass",
          help: previewString("ZoomOutImage", defaultValue: "Zoom out")
        ) {
          scale = max(0.25, scale - 0.25)
        }

        PreviewActionButton(
          systemName: "plus.magnifyingglass",
          help: previewString("ZoomInImage", defaultValue: "Zoom in")
        ) {
          scale = min(6, scale + 0.25)
        }

        PreviewActionButton(
          systemName: "1.magnifyingglass",
          help: previewString("ActualSizeImage", defaultValue: "Actual size")
        ) {
          scale = 1
        }

        Spacer(minLength: 0)

        PreviewActionButton(
          systemName: "xmark",
          help: previewString("CloseImagePreview", defaultValue: "Close")
        ) {
          onClose()
        }
      }
      .padding(10)

      ImageZoomScrollView(
        image: image,
        frameSize: ImageZoomWindowController.imageFrameSize(for: image, scale: scale)
      )
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(Color(nsColor: .textBackgroundColor))
    }
  }
}

struct ImageZoomScrollView: NSViewRepresentable {
  let image: NSImage
  let frameSize: NSSize

  func makeCoordinator() -> Coordinator {
    Coordinator()
  }

  func makeNSView(context: Context) -> NSScrollView {
    let scrollView = PannableScrollView()
    scrollView.borderType = .noBorder
    scrollView.drawsBackground = true
    scrollView.backgroundColor = .textBackgroundColor
    scrollView.hasHorizontalScroller = true
    scrollView.hasVerticalScroller = true
    scrollView.autohidesScrollers = true
    scrollView.allowsMagnification = false

    let documentView = ImageZoomDocumentView()
    scrollView.documentView = documentView
    context.coordinator.documentView = documentView

    return scrollView
  }

  func updateNSView(_ scrollView: NSScrollView, context: Context) {
    guard let documentView = scrollView.documentView as? ImageZoomDocumentView else { return }

    documentView.configure(image: image, imageSize: frameSize)
    scrollView.reflectScrolledClipView(scrollView.contentView)
    context.coordinator.documentView = documentView
  }

  @MainActor
  static func scrolledOrigin(
    currentOrigin: NSPoint,
    dragDelta: NSPoint,
    contentSize: NSSize,
    viewportSize: NSSize
  ) -> NSPoint {
    let maxX = max(0, contentSize.width - viewportSize.width)
    let maxY = max(0, contentSize.height - viewportSize.height)

    return NSPoint(
      x: min(max(currentOrigin.x - dragDelta.x, 0), maxX),
      y: min(max(currentOrigin.y - dragDelta.y, 0), maxY)
    )
  }

  final class Coordinator {
    weak var documentView: ImageZoomDocumentView?
  }
}

final class ImageZoomDocumentView: NSView {
  private static let padding: CGFloat = 16

  private let imageView = NSImageView()

  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)

    wantsLayer = true
    layer?.backgroundColor = NSColor.textBackgroundColor.cgColor

    imageView.imageAlignment = .alignCenter
    imageView.imageFrameStyle = .none
    imageView.imageScaling = .scaleAxesIndependently
    imageView.wantsLayer = true
    imageView.layer?.backgroundColor = NSColor.textBackgroundColor.cgColor
    addSubview(imageView)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(image: NSImage, imageSize: NSSize) {
    let documentSize = NSSize(
      width: imageSize.width + Self.padding * 2,
      height: imageSize.height + Self.padding * 2
    )

    frame = NSRect(origin: .zero, size: documentSize)
    imageView.image = image
    imageView.frame = NSRect(
      x: Self.padding,
      y: Self.padding,
      width: imageSize.width,
      height: imageSize.height
    )
  }
}

final class PannableScrollView: NSScrollView {
  private var lastDragLocation: NSPoint?

  override func mouseDown(with event: NSEvent) {
    lastDragLocation = convert(event.locationInWindow, from: nil)
  }

  override func mouseDragged(with event: NSEvent) {
    guard let lastDragLocation,
          let documentView else {
      super.mouseDragged(with: event)
      return
    }

    let currentLocation = convert(event.locationInWindow, from: nil)
    let dragDelta = NSPoint(
      x: currentLocation.x - lastDragLocation.x,
      y: currentLocation.y - lastDragLocation.y
    )
    let newOrigin = ImageZoomScrollView.scrolledOrigin(
      currentOrigin: contentView.bounds.origin,
      dragDelta: dragDelta,
      contentSize: documentView.bounds.size,
      viewportSize: contentView.bounds.size
    )

    contentView.scroll(to: newOrigin)
    reflectScrolledClipView(contentView)
    self.lastDragLocation = currentLocation
  }

  override func mouseUp(with event: NSEvent) {
    lastDragLocation = nil
  }

  override func mouseExited(with event: NSEvent) {
    lastDragLocation = nil
  }
}
