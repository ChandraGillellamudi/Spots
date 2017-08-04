import Cocoa

extension NSScrollView {
  public var contentOffset: CGPoint {
    get { return documentView!.visibleRect.origin }
    set(newValue) { documentView?.scroll(newValue) }
  }
}
