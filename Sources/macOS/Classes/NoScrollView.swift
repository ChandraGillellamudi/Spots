import Cocoa

fileprivate class SpotClipView: NSClipView {

  override func scroll(to newOrigin: NSPoint) {
    super.scroll(to: newOrigin)
    if let scrollView = superview?.enclosingScrollView as? SpotsScrollView {
//      scrollView.contentOffset = newOrigin
//      scrollView.contentView.scroll(to: newOrigin)
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
//    contentView.postsBoundsChangedNotifications = true
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
