import UIKit

/// A proxy cell that is used for composite views inside other Spotable objects
public class GridComposite: UICollectionViewCell, Composable {

  /// Performs any clean up necessary to prepare the view for use again.
  override public func prepareForReuse() {
    for case let view as ScrollableView in contentView.subviews {
      view.removeFromSuperview()
    }
  }

  override public var canBecomeFocused: Bool {
    return false
  }

  /// This fixes the which view should be focused when navigating between composite spots on tvOS.
  #if os(tvOS)
  public override func didMoveToSuperview() {
    superview?.sendSubview(toBack: self)
  }
  #endif
}
