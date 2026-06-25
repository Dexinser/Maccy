import AppKit
import SwiftUI

struct SelectableTextPreviewView: NSViewRepresentable {
  let text: String
  let selection: PreviewTextSelection

  func makeCoordinator() -> Coordinator {
    Coordinator(selection: selection)
  }

  func makeNSView(context: Context) -> NSScrollView {
    let scrollView = NSScrollView()
    scrollView.borderType = .noBorder
    scrollView.drawsBackground = false
    scrollView.hasVerticalScroller = true
    scrollView.autohidesScrollers = true

    let textView = NSTextView()
    textView.delegate = context.coordinator
    textView.string = text
    textView.isEditable = false
    textView.isSelectable = true
    textView.isRichText = false
    textView.drawsBackground = false
    textView.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
    textView.textColor = .labelColor
    textView.textContainerInset = NSSize(width: 8, height: 8)
    textView.isHorizontallyResizable = false
    textView.isVerticallyResizable = true
    textView.autoresizingMask = [.width]
    textView.textContainer?.widthTracksTextView = true
    textView.textContainer?.containerSize = NSSize(
      width: scrollView.contentSize.width,
      height: .greatestFiniteMagnitude
    )

    scrollView.documentView = textView
    context.coordinator.textView = textView
    return scrollView
  }

  func updateNSView(_ scrollView: NSScrollView, context: Context) {
    context.coordinator.selection = selection

    guard let textView = scrollView.documentView as? NSTextView else { return }
    context.coordinator.textView = textView

    if textView.string != text {
      textView.string = text
      selection.reset()
    }
  }

  final class Coordinator: NSObject, NSTextViewDelegate {
    var selection: PreviewTextSelection
    weak var textView: NSTextView?

    init(selection: PreviewTextSelection) {
      self.selection = selection
    }

    func textViewDidChangeSelection(_ notification: Notification) {
      syncSelection()
    }

    private func syncSelection() {
      guard let textView,
            let range = Range(textView.selectedRange(), in: textView.string) else {
        selection.reset()
        return
      }

      selection.update(selectedText: String(textView.string[range]))
    }
  }
}
