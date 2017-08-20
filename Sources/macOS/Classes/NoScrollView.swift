import Cocoa

fileprivate class SpotClipView: NSClipView {

  override func scroll(to newOrigin: NSPoint) {
    super.scroll(to: newOrigin)

    guard let userInterface = documentView as? UserInterface else {
      return
    }

    guard let view: View = userInterface.view(at: userInterface.selectedIndex) else {
      return
    }

    guard let scrollView = superview?.enclosingScrollView else {
      return
    }

    var actualOffset = scrollView.contentOffset.y + scrollView.contentInsets.top
    var converted = view.convert(view.frame.origin, to: scrollView.documentView)
    converted.y -= scrollView.contentInsets.top
    let newRect = NSRect(origin: converted, size: view.frame.size)
    let visibleRectMaxY = scrollView.documentVisibleRect.maxY - scrollView.contentInsets.top
    let visibleRectMinY = scrollView.documentVisibleRect.minY

    var currentOffset = scrollView.contentOffset
    if newRect.maxY >= visibleRectMaxY {
      currentOffset.y += view.frame.size.height
      scrollView.contentView.scroll(currentOffset)
    } else if visibleRectMinY > newRect.origin.y {
      currentOffset.y -= view.frame.size.height
      scrollView.contentView.scroll(currentOffset)
    }
  }
}

open class NoScrollView: NSScrollView {

  var scrollingEnabled: Bool = true

  open override var verticalScroller: NSScroller? {
    get {
      return nil
    }
    set {}
  }

  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    drawsBackground = false
    hasHorizontalScroller = false
    hasVerticalScroller = false
    scrollsDynamically = true
    automaticallyAdjustsContentInsets = false
    scrollerStyle = .overlay
    contentView = SpotClipView()
    contentView.postsBoundsChangedNotifications = true
//    contentView.postsFrameChangedNotifications = true
  }

  required public init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override open func scrollWheel(with theEvent: NSEvent) {
    if theEvent.scrollingDeltaX != 0.0 && horizontalScroller != nil && scrollingEnabled {
      super.scrollWheel(with: theEvent)
    } else if theEvent.scrollingDeltaY != 0.0 {
      enclosingScrollView?.scrollWheel(with: theEvent)
    }
  }

  static open override func isCompatibleWithResponsiveScrolling() -> Bool {
    return true
  }

  override open var allowsVibrancy: Bool {
    return true
  }
}
