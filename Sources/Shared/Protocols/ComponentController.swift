public protocol ComponentController: class {
  var component: Component { get }

  init(component: Component, injection: ((Self) -> Void)?)

  func componentDidUpdate(_ component: Component)
  func componentDidScroll(_ component: Component)
}

extension ComponentController {
  func componentDidUpdate(_ component: Component) {}
  func componentDidScroll(_ component: Component) {}
}
