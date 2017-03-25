import Cocoa

class GridWrapper: NSCollectionViewItem, Wrappable, Cell {

  public var bounds: CGRect {
    return coreView.bounds
  }

  weak var wrappedView: View?

  public var contentView: View {
    return coreView
  }

  var isFlipped: Bool = true

  open var coreView: FlippedView = FlippedView()

  open override func loadView() {
    view = coreView
  }

  override func viewWillLayout() {
    super.viewWillLayout()

    self.wrappedView?.frame = coreView.bounds
  }

  override func prepareForReuse() {
    wrappedView?.removeFromSuperview()
  }

  override var isSelected: Bool {
    didSet {
      (wrappedView as? ViewStateDelegate)?.viewStateDidChange(viewState)
    }
  }

  var isHighlighted: Bool = false {
    didSet {
      (wrappedView as? ViewStateDelegate)?.viewStateDidChange(viewState)
    }
  }
}
