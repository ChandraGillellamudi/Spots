import Cocoa

extension Component {

  func layoutVerticalCollectionView(_ collectionView: CollectionView, with size: CGSize) {
    guard let collectionViewLayout = collectionView.collectionViewLayout else {
      return
    }

    collectionView.frame.size.width = size.width
    collectionViewLayout.prepare()
    collectionViewLayout.invalidateLayout()

    guard let window = collectionView.window else {
      return
    }

    let collectionViewContentSize = collectionViewLayout.collectionViewContentSize
    let newHeight = collectionViewContentSize.height > size.height
      ? size.height
      : collectionViewContentSize.height
    collectionView.frame.size.width = collectionViewContentSize.width
    collectionView.frame.size.height = collectionViewContentSize.height
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
