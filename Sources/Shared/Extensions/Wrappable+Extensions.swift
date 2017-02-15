public extension Wrappable {

  func configure(with view: View) {
    if let previousView = self.wrappedView {
      previousView.removeFromSuperview()
    }

    view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    view.frame = bounds
    view.isUserInteractionEnabled = false

    contentView.addSubview(view)
    self.wrappedView = view
  }
}
