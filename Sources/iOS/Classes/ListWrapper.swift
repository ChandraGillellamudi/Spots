import UIKit

class ListWrapper: UITableViewCell, Wrappable {

  weak var wrappedView: View?

  override func layoutSubviews() {
    super.layoutSubviews()

    wrappedView?.frame.size = contentView.bounds.size
  }

  override func prepareForReuse() {
    wrappedView?.removeFromSuperview()
  }
}
