import Cocoa

extension NSScrollView {

  convenience init(documentView: View?) {
    self.init()
    self.documentView = documentView
  }

  public var contentOffset: CGPoint {
    get { return contentView.visibleRect.origin }
    set(newValue) { contentView.scroll(newValue) }
  }
}
