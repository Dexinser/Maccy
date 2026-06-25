import SwiftUI

func previewString(_ key: String, defaultValue: String) -> String {
  NSLocalizedString(key, tableName: "PreviewItemView", value: defaultValue, comment: "")
}

struct PreviewActionButton: View {
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
