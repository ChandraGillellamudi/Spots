import Cocoa

public extension NSCollectionView {
  var flowLayout: NSCollectionViewFlowLayout? {
    return collectionViewLayout as? NSCollectionViewFlowLayout
  }
}
