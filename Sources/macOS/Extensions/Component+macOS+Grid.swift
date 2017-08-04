import Cocoa

extension Component {

  func layoutVerticalCollectionView(_ collectionView: CollectionView, with size: CGSize) {
    guard let collectionViewLayout = collectionView.collectionViewLayout else {
      return
    }

    collectionView.frame.size.width = size.width
//    collectionView.frame.origin.y = headerHeight
    collectionViewLayout.prepare()
    collectionViewLayout.invalidateLayout()

    if let window = collectionView.window {
      var collectionViewContentSize = collectionViewLayout.collectionViewContentSize
      collectionView.frame.size.width = collectionViewContentSize.width
//      collectionView.frame.size.height = collectionViewContentSize.height
//      documentView.frame.size = collectionViewContentSize
//      scrollView.frame.size = collectionViewContentSize
//      Swift.print("🗣 \(documentView.frame.size)")
    }
  }

  func resizeVerticalCollectionView(_ collectionView: CollectionView, with size: CGSize, type: ComponentResize) {

    collectionView.collectionViewLayout?.invalidateLayout()

    switch type {
    case .live:
      prepareItems(recreateComposites: false)
      layout(with: size, animated: false)
    case .end:
      layout(with: size, animated: false)
    }
  }
}
