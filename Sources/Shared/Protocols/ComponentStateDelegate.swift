public protocol ComponentStateDelegate: class {
  var identifiers: [String] { get set }

  func handleState(for component: Component, from: ComponentState, to: ComponentState)
}
