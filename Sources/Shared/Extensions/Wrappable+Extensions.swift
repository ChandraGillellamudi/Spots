public extension Wrappable {

  func configure(with view: View) {
    if let previousView = self.wrappedView {
      previousView.removeFromSuperview()
    }

    view.frame.size = frame.size

    configureWrappedView()
    contentView.addSubview(view)
    self.wrappedView = view
  }

  func configureWrappedView() {}
}
