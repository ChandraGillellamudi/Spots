import Cocoa

class ComponentClipView: NSClipView {

  func scrollWithSuperView(_ point: CGPoint) {
    super.scroll(to: point)
  }

  override func scroll(to newOrigin: NSPoint) {
    guard let scrollView = enclosingScrollView?.enclosingScrollView as? SpotsScrollView else {
      return
    }

    scrollView.documentView?.scroll(newOrigin)
  }
}

open class ComponentScrollView: NSScrollView {

  var scrollingEnabled: Bool = true

  open override var verticalScroller: NSScroller? {
    get { return nil }
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
    contentView = ComponentClipView()
  }

  required public init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  open override func scroll(_ point: NSPoint) {
    super.scroll(point)
    Swift.print("\(#file):\(#function):\(#line)")
  }

  override open func scrollWheel(with theEvent: NSEvent) {
    if theEvent.scrollingDeltaX != 0.0 && horizontalScroller != nil && scrollingEnabled {
      super.scrollWheel(with: theEvent)
    } else if theEvent.scrollingDeltaY != 0.0 {
      nextResponder?.scrollWheel(with: theEvent)
    }
  }

  override open var allowsVibrancy: Bool {
    return true
  }
}
