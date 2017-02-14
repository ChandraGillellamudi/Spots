// swiftlint:disable weak_delegate

import UIKit
import Tailor

public class Spot: NSObject, Spotable {

  public static var layout: Layout = Layout(span: 1.0)
  public static var headers: Registry = Registry()
  public static var views: Registry = Registry()
  public static var defaultKind: String = Component.Kind.list.string

  open static var configure: ((_ view: View) -> Void)?

  weak public var focusDelegate: SpotsFocusDelegate?
  weak public var delegate: SpotsDelegate?
  weak public var carouselScrollDelegate: CarouselScrollDelegate?

  public var component: Component
  public var componentKind: Component.Kind = .list
  public var compositeSpots: [CompositeSpot] = []

  public var configure: ((ItemConfigurable) -> Void)? {
    didSet {
      configureClosureDidChange()
    }
  }

  public var spotDelegate: Delegate?
  public var spotDataSource: DataSource?
  public var stateCache: StateCache?

  public var userInterface: UserInterface? {
    return self.view as? UserInterface
  }

  open lazy var pageControl = UIPageControl()
  open lazy var backgroundView = UIView()

  public var view: ScrollView

  public var tableView: TableView? {
    return userInterface as? TableView
  }

  public var collectionView: CollectionView? {
    return userInterface as? CollectionView
  }

  public required init(component: Component) {
    var component = component
    if component.kind.isEmpty {
      component.kind = Spot.defaultKind
    }

    self.component = component

    if let componentKind = Component.Kind(rawValue: component.kind) {
      self.componentKind = componentKind
    }

    if componentKind == .list {
      self.view = TableView()
    } else {
      let collectionViewLayout = CollectionLayout()
      let collectionView = CollectionView(frame: CGRect.zero, collectionViewLayout: collectionViewLayout)

      if componentKind == .carousel {
        self.component.interaction.scrollDirection = .horizontal
        collectionViewLayout.scrollDirection = .horizontal
        collectionView.showsHorizontalScrollIndicator = false
      }

      self.view = collectionView
    }

    super.init()

    if component.layout == nil {
      switch componentKind {
      case .carousel:
        self.component.layout = CarouselSpot.layout
        registerDefaultIfNeeded(view: CarouselSpotCell.self)
      case .grid:
        self.component.layout = GridSpot.layout
        registerDefaultIfNeeded(view: GridSpotCell.self)
      case .list:
        self.component.layout = ListSpot.layout
        registerDefaultIfNeeded(view: ListSpotCell.self)
      case .row:
        self.component.layout = RowSpot.layout
      default:
        break
      }
    }

    userInterface?.register()

    if let componentLayout = self.component.layout,
      let collectionViewLayout = collectionView?.collectionViewLayout as? GridableLayout {
      componentLayout.configure(collectionViewLayout: collectionViewLayout)
    }

    self.spotDataSource = DataSource(spot: self)
    self.spotDelegate = Delegate(spot: self)
  }

  public convenience init(cacheKey: String) {
    let stateCache = StateCache(key: cacheKey)

    self.init(component: Component(stateCache.load()))
    self.stateCache = stateCache
  }

  deinit {
    spotDataSource = nil
    spotDelegate = nil
  }

  public func setup(_ size: CGSize) {
    type(of: self).configure?(view)

    if let tableView = self.tableView {
      setupTableView(tableView, with: size)
    } else if let collectionView = self.collectionView {
      setupCollectionView(collectionView, with: size)
    }

    layout(size)
  }

  public func layout(_ size: CGSize) {
    if let tableView = self.tableView {
      layoutTableView(tableView, with: size)
    } else if let collectionView = self.collectionView {
      layoutCollectionView(collectionView, with: size)
    }

    view.layoutSubviews()
  }

  fileprivate func setupTableView(_ tableView: TableView, with size: CGSize) {
    tableView.dataSource = spotDataSource
    tableView.delegate = spotDelegate
    tableView.rowHeight = UITableViewAutomaticDimension
    tableView.frame.size = size
    tableView.frame.size.width = round(size.width - (tableView.contentInset.left))
    tableView.frame.origin.x = round(size.width / 2 - tableView.frame.width / 2)

    prepareItems()

    var height: CGFloat = 0.0
    for item in component.items {
      height += item.size.height
    }

    tableView.contentSize = CGSize(
      width: tableView.frame.size.width,
      height: height - tableView.contentInset.top - tableView.contentInset.bottom)

    /// On iOS 8 and prior, the second cell always receives the same height as the first cell. Setting estimatedRowHeight magically fixes this issue. The value being set is not relevant.
    if #available(iOS 9, *) {
      return
    } else {
      tableView.estimatedRowHeight = 10
    }
  }

  fileprivate func setupCollectionView(_ collectionView: CollectionView, with size: CGSize) {
    collectionView.frame.size = size
    collectionView.dataSource = spotDataSource
    collectionView.delegate = spotDelegate

    switch component.interaction.scrollDirection {
    case .horizontal:
      setupHorizontalCollectionView(collectionView, with: size)
    case .vertical:
      setupVerticalCollectionView(collectionView, with: size)
    }
  }

  fileprivate func setupHorizontalCollectionView(_ collectionView: CollectionView, with size: CGSize) {
    guard let layout = collectionView.collectionViewLayout as? GridableLayout else {
      return
    }

    collectionView.isScrollEnabled = true
    configurePageControl()

    if collectionView.contentSize.height > 0 {
      collectionView.frame.size.height = collectionView.contentSize.height
    } else {
      var newCollectionViewHeight: CGFloat = 0.0

      newCollectionViewHeight <- component.items.sorted(by: {
        $0.size.height > $1.size.height
      }).first?.size.height

      collectionView.frame.size.height = newCollectionViewHeight

      if collectionView.frame.size.height > 0 {
        collectionView.frame.size.height += layout.sectionInset.top + layout.sectionInset.bottom
      }
    }

    configureCollectionViewHeader(collectionView, with: size)

    CarouselSpot.configure?(collectionView, layout)

    collectionView.frame.size.height += layout.headerReferenceSize.height

    if let componentLayout = component.layout {
      collectionView.frame.size.height += CGFloat(componentLayout.inset.top + componentLayout.inset.bottom)
    }

    if let pageIndicatorPlacement = component.layout?.pageIndicatorPlacement {
      switch pageIndicatorPlacement {
      case .below:
        layout.sectionInset.bottom += pageControl.frame.height
        pageControl.frame.origin.y = collectionView.frame.height
      case .overlay:
        let verticalAdjustment = CGFloat(2)
        pageControl.frame.origin.y = collectionView.frame.height - pageControl.frame.height - verticalAdjustment
      }
    }
  }

  fileprivate func setupVerticalCollectionView(_ collectionView: CollectionView, with size: CGSize) {
    guard let collectionViewLayout = collectionView.collectionViewLayout as? GridableLayout else {
      return
    }

    configureCollectionViewHeader(collectionView, with: size)

    GridSpot.configure?(collectionView, collectionViewLayout)
  }

  fileprivate func configureCollectionViewHeader(_ collectionView: CollectionView, with size: CGSize) {
    guard let collectionViewLayout = collectionView.collectionViewLayout as? GridableLayout else {
      return
    }

    guard !component.header.isEmpty else {
      return
    }

    guard let view = Configuration.views.make(component.header)?.view as? Componentable else {
      return
    }

    collectionViewLayout.headerReferenceSize.width = collectionView.frame.size.width
    collectionViewLayout.headerReferenceSize.height = view.frame.size.height

    if collectionViewLayout.headerReferenceSize.width == 0.0 {
      collectionViewLayout.headerReferenceSize.width = size.width
    }

    if collectionViewLayout.headerReferenceSize.height == 0.0 {
      collectionViewLayout.headerReferenceSize.height = view.preferredHeaderHeight
    }
  }

  fileprivate func layoutCollectionView(_ collectionView: CollectionView, with size: CGSize) {
    prepareItems()

    switch component.interaction.scrollDirection {
    case .horizontal:
      layoutHorizontalCollectionView(collectionView, with: size)
    case .vertical:
      layoutVerticalCollectionView(collectionView, with: size)
    }
  }

  fileprivate func layoutTableView(_ tableView: TableView, with size: CGSize) {
    tableView.frame.size.width = round(size.width - (tableView.contentInset.left))
    tableView.frame.origin.x = round(size.width / 2 - tableView.frame.width / 2)
  }

  fileprivate func layoutHorizontalCollectionView(_ collectionView: CollectionView, with size: CGSize) {
    guard let collectionViewLayout = collectionView.collectionViewLayout as? GridableLayout else {
      return
    }

    collectionViewLayout.prepare()
    collectionViewLayout.invalidateLayout()
    collectionView.frame.size.width = size.width
    collectionView.frame.size.height = collectionViewLayout.contentSize.height
  }

  fileprivate func layoutVerticalCollectionView(_ collectionView: CollectionView, with size: CGSize) {
    guard let collectionViewLayout = collectionView.collectionViewLayout as? GridableLayout else {
      return
    }

    collectionViewLayout.prepare()
    collectionViewLayout.invalidateLayout()
    collectionView.frame.size = collectionViewLayout.collectionViewContentSize
  }

  func registerDefaultIfNeeded(view: View.Type) {
    guard Configuration.views.storage[Configuration.views.defaultIdentifier] == nil else {
      return
    }

    Configuration.views.defaultItem = Registry.Item.classType(view)
  }

  private func configurePageControl() {
    guard let placement = component.layout?.pageIndicatorPlacement else {
      pageControl.removeFromSuperview()
      return
    }

    pageControl.numberOfPages = component.items.count
    pageControl.frame.origin.x = 0
    pageControl.frame.size.height = 22

    switch placement {
    case .below:
      pageControl.frame.size.width = backgroundView.frame.width
      pageControl.pageIndicatorTintColor = .lightGray
      pageControl.currentPageIndicatorTintColor = .gray
      backgroundView.addSubview(pageControl)
    case .overlay:
      pageControl.frame.size.width = view.frame.width
      pageControl.pageIndicatorTintColor = nil
      pageControl.currentPageIndicatorTintColor = nil
      view.addSubview(pageControl)
    }
  }

  public func sizeForItem(at indexPath: IndexPath) -> CGSize {
    return CGSize(
      width:  item(at: indexPath)?.size.width  ?? 0.0,
      height: item(at: indexPath)?.size.height ?? 0.0
    )
  }

  public func register() {

  }

  /// Scroll to a specific item based on predicate.
  ///
  /// - parameter predicate: A predicate closure to determine which item to scroll to
  public func scrollTo(_ predicate: (Item) -> Bool) {
    guard let collectionView = self.collectionView,
    let collectionViewLayout = collectionView.collectionViewLayout as? GridableLayout
      else {
        return
    }

    if let index = items.index(where: predicate) {
      let pageWidth: CGFloat = collectionView.frame.size.width - collectionViewLayout.sectionInset.right
        + collectionViewLayout.sectionInset.left

      collectionView.setContentOffset(CGPoint(x: pageWidth * CGFloat(index), y:0), animated: true)

      guard let item = item(at: index) else {
        return
      }

      carouselScrollDelegate?.spotableCarouselDidEndScrolling(self, item: item)
    }
  }

  /// Scrolls the collection view contents until the specified item is visible.
  ///
  /// - parameter index: The index path of the item to scroll into view.
  /// - parameter position: An option that specifies where the item should be positioned when scrolling finishes.
  /// - parameter animated: Specify true to animate the scrolling behavior or false to adjust the scroll view’s visible content immediately.
  public func scrollTo(index: Int, position: UICollectionViewScrollPosition = .centeredHorizontally, animated: Bool = true) {
    guard let collectionView = self.collectionView else {
      return
    }

    collectionView.scrollToItem(at: IndexPath(item: index, section: 0),
                                at: position, animated: animated)

    guard let item = item(at: index) else {
      return
    }

    carouselScrollDelegate?.spotableCarouselDidEndScrolling(self, item: item)
  }
}
