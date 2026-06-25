import SwiftUI

struct ClipboardFilterPickerView: View {
  @Binding var activeFilter: ClipboardFilter

  var body: some View {
    Picker("", selection: $activeFilter) {
      ForEach(ClipboardFilter.allCases) { filter in
        Text(filter.description)
          .tag(filter)
      }
    }
    .pickerStyle(.segmented)
    .labelsHidden()
    .controlSize(.small)
    .frame(width: 260)
  }
}

#Preview {
  ClipboardFilterPickerView(activeFilter: .constant(.all))
    .padding()
}
