import UIKit

extension DataSource: UICollectionViewDataSource {

  /// Asks the data source for the number of items in the specified section. (required)
  ///
  /// - parameter collectionView: An object representing the collection view requesting this information.
  /// - parameter section:        An index number identifying a section in collectionView. This index value is 0-based.
  ///
  /// - returns: The number of rows in section.
  @available(iOS 6.0, *)
  public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    guard let component = component else {
      return 0
    }

    return component.model.items.count
  }

  /// Asks your data source object to provide a supplementary view to display in the collection view.
  /// A configured supplementary view object. You must not return nil from this method.
  ///
  /// - parameter collectionView: The collection view requesting this information.
  /// - parameter kind:           The kind of supplementary view to provide. The value of this string is defined by the layout object that supports the supplementary view.
  /// - parameter indexPath:      The index path that specifies the location of the new supplementary view.
  ///
  /// - returns: A configured supplementary view object.
  public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
    guard let component = component,
      let collectionViewLayout = collectionView.collectionViewLayout as? GridableLayout,
      !kind.isEmpty else {
        return UICollectionReusableView()
    }

    let headerFooterItem: Item?
    let identifier: String
    var viewHeight: CGFloat = 0.0

    switch kind {
    case UICollectionElementKindSectionHeader:
      headerFooterItem = component.model.header
      let kind = headerFooterItem?.kind ?? ""

      if kind.isEmpty {
        return UICollectionReusableView()
      } else {
        identifier = kind
      }
      viewHeight = collectionViewLayout.headerReferenceSize.height

    case UICollectionElementKindSectionFooter:
      headerFooterItem = component.model.footer
      let kind = headerFooterItem?.kind ?? ""
      identifier = kind
      viewHeight = collectionViewLayout.footerHeight
    default:
      return UICollectionReusableView()
    }

    guard var resolvedItem = headerFooterItem else {
      return UICollectionReusableView()
    }

    let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                               withReuseIdentifier: identifier,
                                                               for: indexPath)

    switch view {
    case let view as GridHeaderFooterWrapper:
      if let (_, resolvedView) = Configuration.views.make(identifier),
        let customView = resolvedView {
        view.configure(with: customView)
        view.frame.size.height = viewHeight
        view.frame.size.width = collectionView.frame.size.width

        (customView as? ItemConfigurable)?.configure(&resolvedItem)
      }
    case let view as ItemConfigurable:
      view.configure(&resolvedItem)
    default:
      break
    }

    return view
  }

  /// Asks the data source for the number of items in the specified section. (required)
  ///
  /// - parameter collectionView: An object representing the collection view requesting this information.
  /// - parameter section:        An index number identifying a section in collectionView. This index value is 0-based.
  ///
  /// - returns: The number of rows in section.
  public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    guard let component = component, indexPath.item < component.model.items.count else {
      return UICollectionViewCell()
    }

    component.model.items[indexPath.item].index = indexPath.item

    let reuseIdentifier = component.identifier(for: indexPath)
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
    viewPreparer.prepareView(cell, atIndex: indexPath.item, in: component, parentFrame: cell.bounds)

    return cell
  }
}

extension DataSource: UITableViewDataSource {

  /// Tells the data source to return the number of rows in a given section of a table view. (required)
  ///
  /// - parameter tableView: The table-view object requesting this information.
  /// - parameter section: An index number identifying a section in tableView.
  ///
  /// - returns: The number of rows in section.
  public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    guard let component = component else {
      return 0
    }

    return component.model.items.count
  }

  /// Asks the data source for a cell to insert in a particular location of the table view. (required)
  ///
  /// - parameter tableView: A table-view object requesting the cell.
  /// - parameter indexPath: An index path locating a row in tableView.
  ///
  /// - returns: An object inheriting from UITableViewCell that the table view can use for the specified row. Will return the default table view cell for the current component based of kind.
  public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let component = component, indexPath.item < component.model.items.count else {
      return UITableViewCell()
    }

    if indexPath.item < component.model.items.count {
      component.model.items[indexPath.item].index = indexPath.row
    }

    let reuseIdentifier = component.identifier(for: indexPath)
    let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
    viewPreparer.prepareView(cell, atIndex: indexPath.row, in: component, parentFrame: cell.bounds)

    return cell
  }
}
