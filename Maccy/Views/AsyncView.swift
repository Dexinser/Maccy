import SwiftUI

enum AsyncViewState<T> {
  case loading
  case failed
  case loaded(T)
}

@MainActor
final class AsyncViewModel<ID: Equatable, Value>: ObservableObject {
  @Published private(set) var viewState = AsyncViewState<Value>.loading

  var loadedValue: Value? {
    if case .loaded(let value) = viewState {
      return value
    }

    return nil
  }

  private var currentID: ID?
  private var task: Task<Void, Never>?

  deinit {
    task?.cancel()
  }

  func load(id: ID, operation: @escaping () async throws -> Value) {
    currentID = id
    task?.cancel()
    viewState = .loading

    task = Task { @MainActor in
      do {
        let result = try await operation()
        guard !Task.isCancelled, currentID == id else { return }
        viewState = .loaded(result)
      } catch {
        guard !Task.isCancelled, currentID == id else { return }
        viewState = .failed
      }
    }
  }
}

struct AsyncView<Value, Content: View, Placeholder: View>: View {
  let id: AnyHashable
  let operation: () async throws -> Value
  @ViewBuilder var content: (Value) -> Content
  @ViewBuilder var placeholder: () -> Placeholder

  @StateObject private var model = AsyncViewModel<AnyHashable, Value>()

  init(
    id: AnyHashable,
    operation: @escaping () async throws -> Value,
    @ViewBuilder content: @escaping (Value) -> Content,
    @ViewBuilder placeholder: @escaping () -> Placeholder
  ) {
    self.id = id
    self.operation = operation
    self.content = content
    self.placeholder = placeholder
  }

  var body: some View {
    Group {
      switch model.viewState {
      case .loading, .failed:
        placeholder()
      case .loaded(let value):
        content(value)
      }
    }.task(id: id) {
      model.load(id: id, operation: operation)
    }
  }
}
