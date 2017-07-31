import Cocoa

open class SpotsScrollView: NSScrollView {
  override open var isFlipped: Bool { return true }

  override public var contentOffset: CGPoint {
    get {
      return contentView.visibleRect.origin
    }
    set(newValue) {
      contentView.scroll(to: newValue)
      alignViews()
    }
  }

  func alignViews() {
    CATransaction.begin()
    Dispatch.after(seconds: 0.05) {
      self.layoutViews(animated: false)
      CATransaction.commit()
    }
  }

  /// When enabled, the last `Component` in the collection will be stretched to occupy the remaining space.
  /// This can be enabled globally by setting `Configuration.stretchLastComponent` to `true`.
  ///
  /// ```
  ///  Enabled    Disabled
  ///  --------   --------
  /// ||¯¯¯¯¯¯|| ||¯¯¯¯¯¯||
  /// ||      || ||      ||
  /// ||______|| ||______||
  /// ||¯¯¯¯¯¯|| ||¯¯¯¯¯¯||
  /// ||      || ||      ||
  /// ||      || ||______||
  /// ||______|| |        |
  ///  --------   --------
  /// ```
  public var stretchLastComponent = Configuration.stretchLastComponent

  /// A KVO context used to monitor changes in contentSize, frames and bounds
  let subviewContext: UnsafeMutableRawPointer? = UnsafeMutableRawPointer(mutating: nil)

  /// Toggles if animations should be enabled or not.
  public var isAnimationsEnabled: Bool = false
  public var inset: Inset?

  /// A collection of NSView's that resemble the order of the views in the scroll view.
  fileprivate var observedViews = [NSView]()

  open var forceUpdate = false {
    didSet {
      if forceUpdate {
        layoutSubtreeIfNeeded()
      }
    }
  }

  /// The document view of SpotsScrollView.
  lazy open var componentsView: SpotsContentView = {
    let contentView = SpotsContentView()
//    contentView.autoresizingMask = [.viewWidthSizable, .viewHeightSizable]
//    contentView.autoresizesSubviews = true
    return contentView
  }()

  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    let flippedView = FlippedView()
    self.documentView = flippedView
    flippedView.addSubview(componentsView)
    drawsBackground = false
    NotificationCenter.default.addObserver(self, selector: #selector(boundsDidChange(_:)), name: NSNotification.Name.NSViewBoundsDidChange, object: nil)
  }

  func boundsDidChange(_ notification: Notification) {
//    layoutViews(animated: false)
  }

  required public init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  /// Cleanup observers.
  deinit {
    for subview in observedViews {
      unobserveView(subview)
    }
  }

  private func observeView(_ view: NSView) {
    guard !observedViews.contains(where: { $0 == view }) else {
      return
    }

    if let scrollView = view as? ScrollView {
//      scrollView.addObserver(self, forKeyPath: #keyPath(frame), options: [.new, .old], context: subviewContext)
//      scrollView.addObserver(self, forKeyPath: #keyPath(bounds), options: .old, context: subviewContext)
    } else {
      view.addObserver(self, forKeyPath: #keyPath(frame), options: .old, context: subviewContext)
      view.addObserver(self, forKeyPath: #keyPath(bounds), options: .old, context: subviewContext)
    }

    observedViews.append(view)
  }

  private func unobserveView(_ view: NSView) {
    guard let index = observedViews.index(where: { $0 == view }) else {
      return
    }

    if let scrollView = view as? ScrollView {
//      scrollView.removeObserver(self, forKeyPath: #keyPath(frame), context: subviewContext)
//      scrollView.removeObserver(self, forKeyPath: #keyPath(bounds), context: subviewContext)
    } else {
      view.removeObserver(self, forKeyPath: #keyPath(frame), context: subviewContext)
      view.removeObserver(self, forKeyPath: #keyPath(bounds), context: subviewContext)
    }

    observedViews.remove(at: index)
  }

  /// A subview was added to the container.
  ///
  /// - Parameter subview: The subview that was added.
  func didAddSubviewToContainer(_ subview: View) {
    guard componentsView.subviews.index(of: subview) != nil else {
      return
    }

    for subview in componentsView.subviews {
      observeView(subview)
    }
    layoutViews(animated: true)
  }

  /// Will remove subview from container.
  ///
  /// - Parameter subview: The subview that will be removed.
  open override func willRemoveSubview(_ subview: View) {
    unobserveView(subview)
    layoutViews(animated: true)
  }

  open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
    if let change = change, let view = object as? View, context == subviewContext {
      if let value = change[NSKeyValueChangeKey.oldKey] as? NSValue {
        guard view.frame.intersects(visibleRect) else {
          return
        }

        guard let keyPath = keyPath else {
          return
        }

        switch keyPath {
        case #keyPath(frame):
          if value.rectValue != view.frame {
            layoutViews(animated: false)
          }
        default:
//          Swift.print(keyPath)
          break
        }
      }
    }
  }

  open func isCompatibleWithResponsiveScrolling() -> Bool {
    return true
  }

  open override func viewDidMoveToWindow() {
    layoutSubtreeIfNeeded()
  }

  open override func layoutSubtreeIfNeeded() {
    super.layoutSubtreeIfNeeded()
    layoutViews(animated: false)
  }

  /// Layout all subviews in the collection ordered by `subviewsInLayoutOrder` on `SpotsContentView`.
  ///
  /// - Parameter animated: Determines if animations should be used when updating the frames of the
  ///                       underlaying views.
  public func layoutViews(animated: Bool = true) {
    guard superview != nil else {
      return
    }

    if #available(OSX 10.12, *) {
      // Workaround to fix the contentInset when using tabs.
      frame.size.width -= 1
      frame.size.width += 1
    }

    guard let window = window else {
      return
    }

    guard let superview = superview else {
      return
    }

    componentsView.frame.size = bounds.size

    var yOffsetOfCurrentSubview: CGFloat = 0.0
    var contentOffset = self.contentOffset

    for case let scrollView as ScrollView in componentsView.subviewsInLayoutOrder {
      var frame = scrollView.frame
      var contentOffset = scrollView.contentOffset

      if self.contentOffset.y < yOffsetOfCurrentSubview {
        contentOffset.y = 0
        frame.origin.y = yOffsetOfCurrentSubview
      } else {
        contentOffset.y = self.contentOffset.y - yOffsetOfCurrentSubview
        frame.origin.y = self.contentOffset.y
      }

      let remainingBoundsHeight = fmax(documentView!.visibleRect.maxY - frame.minY, 0.0)
      let contentHeight: CGFloat
      var shouldResize: Bool = true

      guard let scrollViewDocumentView = scrollView.documentView else {
        return
      }

      switch scrollViewDocumentView {
      case let collectionView as CollectionView:
        shouldResize = collectionView.flowLayout?.scrollDirection == .vertical
        contentHeight = collectionView.collectionViewLayout?.collectionViewContentSize.height ?? 0.0
      case let tableView as TableView:
        contentHeight = tableView.frame.size.height
      default:
        contentHeight = scrollView.frame.size.height
      }

      let remainingContentHeight = fmax(contentHeight - contentOffset.y, 0.0)
      frame.size.width = ceil(componentsView.frame.size.width)
      frame.size.height = ceil(fmin(remainingBoundsHeight, remainingContentHeight))
      yOffsetOfCurrentSubview += contentHeight

      if shouldResize {
        if animated == true {
          scrollView.animator().frame = frame
        } else {
          CATransaction.begin()
          CATransaction.setDisableActions(true)
          scrollView.frame = frame
          CATransaction.commit()
        }
      }

      scrollViewDocumentView.enclosingScrollView?.hasVerticalScroller = false
      scrollViewDocumentView.scroll(CGPoint(x: Int(contentOffset.x), y: Int(contentOffset.y)))
    }

    let frameComparison: CGFloat = frame.height - contentInsets.top - CGFloat(self.inset?.bottom ?? 0.0)
    let newSize = CGSize(width: frame.width, height: fmax(yOffsetOfCurrentSubview, frameComparison))

    componentsView.setFrameSize(newSize)
    documentView?.setFrameSize(newSize)
  }

  open override func scroll(_ point: NSPoint) {
    super.scroll(point)
    layoutViews(animated: false)
  }

  public func flippedViewDidScroll(_ flippedView: FlippedView, to point: NSPoint) {
    Swift.print(point)
  }
}
