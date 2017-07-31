import Cocoa

extension NSScrollView {
  public var contentOffset: CGPoint {
    get { return contentView.visibleRect.origin }
    set(newValue) { contentView.scroll(newValue) }
  }
}
