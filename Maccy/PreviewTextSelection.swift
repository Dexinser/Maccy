import Observation

@Observable
final class PreviewTextSelection {
  private(set) var textForCopy = ""

  var canCopySelection: Bool {
    !textForCopy.isEmpty
  }

  func update(selectedText: String) {
    textForCopy = selectedText
  }

  func reset() {
    textForCopy = ""
  }
}
