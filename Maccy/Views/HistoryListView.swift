import Defaults
import SwiftUI

struct HistoryListView: View {
  @Binding var searchQuery: String
  @FocusState.Binding var searchFocused: Bool

  @State private var renderedUnpinnedCount = IncrementalRenderWindow.initialLimit

  @Environment(AppState.self) private var appState
  @Environment(ModifierFlags.self) private var modifierFlags
  @Environment(\.scenePhase) private var scenePhase

  @Default(.pinTo) private var pinTo
  @Default(.previewDelay) private var previewDelay
  @Default(.showFooter) private var showFooter

  private var visiblePinnedItems: [HistoryItemDecorator] {
    appState.history.pinnedItems.filter(\.isVisible)
  }
  private var visibleUnpinnedItems: [HistoryItemDecorator] {
    appState.history.unpinnedItems.filter(\.isVisible)
  }
  private var renderedUnpinnedItems: [HistoryItemDecorator] {
    Array(visibleUnpinnedItems.prefix(renderedUnpinnedCount))
  }
  private var showPinsSeparator: Bool {
    pinsVisible && !visibleUnpinnedItems.isEmpty
  }

  private var pinsVisible: Bool {
    return !visiblePinnedItems.isEmpty
  }

  private var moreUnpinnedItemsVisible: Bool {
    renderedUnpinnedCount < visibleUnpinnedItems.count
  }

  private var pasteStackVisible: Bool {
    if let stack = appState.history.pasteStack,
       !stack.items.isEmpty {
      return true
    }
    return false
  }

  private var topPadding: CGFloat {
    return Popup.verticalSeparatorPadding
  }

  private var bottomPadding: CGFloat {
    return showFooter
      ? Popup.verticalSeparatorPadding
      : (Popup.verticalSeparatorPadding - 1)
  }

  private func topSeparator() -> some View {
    Divider()
      .padding(.horizontal, Popup.horizontalSeparatorPadding)
      .padding(.top, Popup.verticalSeparatorPadding)
  }

  @ViewBuilder
  private func bottomSeparator() -> some View {
    Divider()
      .padding(.horizontal, Popup.horizontalSeparatorPadding)
      .padding(.bottom, Popup.verticalSeparatorPadding)
  }

  @ViewBuilder
  private func separator() -> some View {
    Divider()
      .padding(.horizontal, Popup.horizontalSeparatorPadding)
      .padding(.vertical, Popup.verticalSeparatorPadding)
  }

  private func resetRenderedUnpinnedItems(total: Int) {
    renderedUnpinnedCount = IncrementalRenderWindow.resetCount(total: total)
  }

  private func renderMoreUnpinnedItems(total: Int) {
    renderedUnpinnedCount = IncrementalRenderWindow.expandedCount(
      total: total,
      current: renderedUnpinnedCount
    )
  }

  private func renderLeadSelectionIfNeeded(in items: [HistoryItemDecorator]) {
    guard let leadSelection = appState.navigator.leadSelection,
          let index = items.firstIndex(where: { $0.id == leadSelection })
    else { return }

    renderedUnpinnedCount = IncrementalRenderWindow.countIncluding(
      index: index,
      current: renderedUnpinnedCount,
      total: items.count
    )
  }

  var body: some View {
    let unpinnedItems = visibleUnpinnedItems
    let renderedItems = renderedUnpinnedItems
    let topPinsVisible = pinTo == .top && pinsVisible
    let bottomPinsVisible = pinTo == .bottom && pinsVisible
    let topSeparatorVisible = topPinsVisible || pasteStackVisible
    let bottomSeparatorVisible = bottomPinsVisible
    let scrollTopPadding = topSeparatorVisible ? Popup.verticalSeparatorPadding : topPadding
    let scrollBottomPadding = bottomSeparatorVisible ? Popup.verticalSeparatorPadding : bottomPadding

    VStack(spacing: 0) {
      if let stack = appState.history.pasteStack,
         !stack.items.isEmpty {
        PasteStackView(stack: stack)

        if topPinsVisible {
          separator()
        }
      }

      if topPinsVisible {
        PinsView(items: visiblePinnedItems)
      }

      if topSeparatorVisible {
        topSeparator()
      }
    }
    .padding(.top, topSeparatorVisible ? topPadding : 0)
    .readHeight(appState, into: \.popup.extraTopHeight)

    ScrollView {
      ScrollViewReader { proxy in
        VStack(spacing: 0) {
          MultipleSelectionListView(items: renderedItems) { previous, item, next, index in
            HistoryItemView(item: item, previous: previous, next: next, index: index)
          }

          if moreUnpinnedItemsVisible {
            ProgressView()
              .controlSize(.small)
              .frame(maxWidth: .infinity)
              .padding(.vertical, 8)
              .onAppear {
                renderMoreUnpinnedItems(total: unpinnedItems.count)
              }
          }
        }
        .padding(.top, scrollTopPadding)
        .padding(.bottom, scrollBottomPadding)
        .task(id: appState.navigator.scrollTarget) {
          renderLeadSelectionIfNeeded(in: unpinnedItems)
          guard appState.navigator.scrollTarget != nil else { return }

          try? await Task.sleep(for: .milliseconds(10))
          guard !Task.isCancelled else { return }

          if let selection = appState.navigator.scrollTarget {
            proxy.scrollTo(selection)
            appState.navigator.scrollTarget = nil
          }
        }
        .onAppear {
          resetRenderedUnpinnedItems(total: unpinnedItems.count)
        }
        .onChange(of: appState.history.items.map(\.id)) {
          resetRenderedUnpinnedItems(total: unpinnedItems.count)
          renderLeadSelectionIfNeeded(in: unpinnedItems)
        }
        .onChange(of: appState.navigator.leadSelection) {
          renderLeadSelectionIfNeeded(in: unpinnedItems)
        }
        .onChange(of: scenePhase) {
          if scenePhase == .active {
            searchFocused = true
            appState.navigator.isKeyboardNavigating = true
            appState.navigator.select(item: appState.history.unpinnedItems.first ?? appState.history.pinnedItems.first)
            appState.preview.enableAutoOpen()
            appState.preview.resetAutoOpenSuppression()
            appState.preview.startAutoOpen()
          } else {
            modifierFlags.flags = []
            appState.navigator.isKeyboardNavigating = true
            appState.preview.cancelAutoOpen()
          }
        }
        // Calculate the total height inside a scroll view.
        .background {
          GeometryReader { geo in
            Color.clear
              .task(id: appState.popup.needsResize) {
                try? await Task.sleep(for: .milliseconds(10))
                guard !Task.isCancelled else { return }

                if appState.popup.needsResize {
                  appState.popup.resize(height: geo.size.height)
                }
              }
          }
        }
      }
      .contentMargins(.leading, 10, for: .scrollIndicators)
      .contentMargins(.top, scrollTopPadding, for: .scrollIndicators)
      .contentMargins(.bottom, scrollBottomPadding, for: .scrollIndicators)
    }

    VStack(spacing: 0) {
      if bottomSeparatorVisible {
        bottomSeparator()
      }

      if bottomPinsVisible {
        PinsView(items: visiblePinnedItems)
      }
    }
    .padding(.bottom, bottomSeparatorVisible ? bottomPadding : 0)
    .readHeight(appState, into: \.popup.extraBottomHeight)
  }
}
