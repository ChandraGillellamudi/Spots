// swiftlint:disable weak_delegate

import Cocoa
import Tailor

public class Spot: NSObject, Spotable {

  /// An enum layout type
  ///
  /// - Grid: Resolves to NSCollectionViewGridLayout
  /// - Left: Resolves to CollectionViewLeftLayout
  /// - Flow: Resolves to NSCollectionViewFlowLayout
  public enum LayoutType: String {
    case grid
    case left
    case flow
  }

  public struct Key {
    public static let titleSeparator = "title-separator"
    public static let titleFontSize = "title-font-size"
    public static let titleTopInset = "title-top-inset"
    public static let titleBottomInset = "title-bottom-inset"
    public static let titleLeftInset = "title-left-inset"
    public static let contentInsetsTop = "inset-top"
    public static let contentInsetsLeft = "inset-left"
    public static let contentInsetsBottom = "inset-bottom"
    public static let contentInsetsRight = "inset-right"
    public static let doubleAction = "double-click"

    /// The key for minimum interitem spacing
    public static let minimumInteritemSpacing = "item-spacing"
    /// The key for minimum line spacing
    public static let minimumLineSpacing = "line-spacing"
    /// The key for title left margin
    public static let titleLeftMargin = "title-left-margin"
    /// The key for layout
    public static let layout = "layout"
    /// The key for grid layout maximum item width
    public static let gridLayoutMaximumItemWidth = "item-width-max"
    /// The key for grid layout maximum item height
    public static let gridLayoutMaximumItemHeight = "item-height-max"
    /// The key for grid layout minimum item width
    public static let gridLayoutMinimumItemWidth = "item-min-width"
    /// The key for grid layout minimum item height
    public static let gridLayoutMinimumItemHeight = "item-min-height"
  }

  public struct Default {
    public struct Flow {
      /// Default minimum interitem spacing
      public static var minimumInteritemSpacing: CGFloat = 0.0
      /// Default minimum line spacing
      public static var minimumLineSpacing: CGFloat = 0.0
    }

    public static var titleSeparator: Bool = true
    public static var titleFontSize: CGFloat = 18.0
    public static var titleLeftInset: CGFloat = 0.0
    public static var titleTopInset: CGFloat = 10.0
    public static var titleBottomInset: CGFloat = 10.0
    public static var contentInsetsTop: CGFloat = 0.0
    public static var contentInsetsLeft: CGFloat = 0.0
    public static var contentInsetsBottom: CGFloat = 0.0
    public static var contentInsetsRight: CGFloat = 0.0

    public static var defaultLayout: String = LayoutType.flow.rawValue
    /// Default grid layout maximum item width
    public static var gridLayoutMaximumItemWidth = 120
    /// Default grid layout maximum item height
    public static var gridLayoutMaximumItemHeight = 120
    /// Default grid layout minimum item width
    public static var gridLayoutMinimumItemWidth = 80
    /// Default grid layout minimum item height
    public static var gridLayoutMinimumItemHeight = 80
    /// Default top section inset
    public static var sectionInsetTop: CGFloat = 0.0
    /// Default left section inset
    public static var sectionInsetLeft: CGFloat = 0.0
    /// Default right section inset
    public static var sectionInsetRight: CGFloat = 0.0
    /// Default bottom section inset
    public static var sectionInsetBottom: CGFloat = 0.0
  }

  public static var layout: Layout = Layout(span: 1.0)
  public static var headers: Registry = Registry()
  public static var views: Registry = Registry()
  public static var defaultKind: String = Component.Kind.list.string

  open static var configure: ((_ view: View) -> Void)?

  weak public var focusDelegate: SpotsFocusDelegate?
  weak public var delegate: SpotsDelegate?

  var headerHeight = CGFloat(0.0)
  var footerHeight = CGFloat(0.0)

  public var component: Component
  public var componentKind: Component.Kind = .list
  public var compositeSpots: [CompositeSpot] = []
  public var configure: ((ItemConfigurable) -> Void)?
  public var spotDelegate: Delegate?
  public var spotDataSource: DataSource?
  public var stateCache: StateCache?
  public var userInterface: UserInterface?
  open var gradientLayer: CAGradientLayer?

  public var responder: NSResponder {
    switch self.userInterface {
    case let tableView as TableView:
      return tableView
    case let collectionView as CollectionView:
      return collectionView
    default:
      return scrollView
    }
  }

  public var nextResponder: NSResponder? {
    get {
      switch self.userInterface {
      case let tableView as TableView:
        return tableView.nextResponder
      case let collectionView as CollectionView:
        return collectionView.nextResponder
      default:
        return scrollView.nextResponder
      }
    }
    set {
      switch self.userInterface {
      case let tableView as TableView:
        tableView.nextResponder = newValue
      case let collectionView as CollectionView:
        collectionView.nextResponder = newValue
      default:
        scrollView.nextResponder = newValue
      }
    }
  }

  public func deselect() {
    switch self.userInterface {
    case let tableView as TableView:
      tableView.deselectAll(nil)
    case let collectionView as CollectionView:
      collectionView.deselectAll(nil)
    default: break
    }
  }

//  open var layout: NSCollectionViewLayout

  open lazy var titleView: NSTextField = {
    let titleView = NSTextField()
    titleView.isEditable = false
    titleView.isSelectable = false
    titleView.isBezeled = false
    titleView.textColor = NSColor.gray
    titleView.drawsBackground = false

    return titleView
  }()

  lazy var lineView: NSView = {
    let lineView = NSView()
    lineView.frame.size.height = 1
    lineView.wantsLayer = true
    lineView.layer?.backgroundColor = NSColor.gray.withAlphaComponent(0.2).cgColor

    return lineView
  }()

  open lazy var scrollView: ScrollView = {
    let scrollView = ScrollView()
    scrollView.documentView = NSView()
    return scrollView
  }()

  public var view: ScrollView {
    return scrollView
  }

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
      userInterface = TableView()
    } else {
      let collectionView = CollectionView(frame: CGRect.zero)
      let collectionViewLayout = Spot.setupLayout(component)
      collectionView.collectionViewLayout = collectionViewLayout

      if componentKind == .carousel {
        self.component.interaction.scrollDirection = .horizontal
        (collectionViewLayout as? FlowLayout)?.scrollDirection = .horizontal
      }

      userInterface = collectionView
    }

    userInterface?.register()

    super.init()

    if component.layout == nil {
      switch componentKind {
      case .carousel:
        self.component.layout = CarouselSpot.layout
//        registerDefaultIfNeeded(view: GridSpotItem.self)
      case .grid:
        self.component.layout = GridSpot.layout
//        registerDefaultIfNeeded(view: GridSpotItem.self)
      case .list:
        self.component.layout = ListSpot.layout
        registerDefaultIfNeeded(view: ListSpotItem.self)
      case .row:
        self.component.layout = RowSpot.layout
      default:
        break
      }
    }

    if let componentLayout = self.component.layout,
      let collectionViewLayout = collectionView?.collectionViewLayout as? FlowLayout {
      componentLayout.configure(collectionViewLayout: collectionViewLayout)
    }

    self.spotDataSource = DataSource(spot: self)
    self.spotDelegate = Delegate(spot: self)

    if let componentLayout = component.layout {
      configure(with: componentLayout)
    }
  }

  public convenience init(cacheKey: String) {
    let stateCache = StateCache(key: cacheKey)

    self.init(component: Component(stateCache.load()))
    self.stateCache = stateCache
  }

  deinit {
    spotDataSource = nil
    spotDelegate = nil
    userInterface = nil
  }

  public func configure(with layout: Layout) {

  }

  fileprivate func configureDataSourceAndDelegate() {
    if let tableView = self.tableView {
      tableView.dataSource = spotDataSource
      tableView.delegate = spotDelegate
    } else if let collectionView = self.collectionView {
      collectionView.dataSource = spotDataSource
      collectionView.delegate = spotDelegate
    }
  }

  public func setup(_ size: CGSize) {
    type(of: self).configure?(view)

    if let layout = component.layout {
      scrollView.contentInsets.top = CGFloat(layout.inset.top)
      scrollView.contentInsets.left = CGFloat(layout.inset.left)
      scrollView.contentInsets.bottom = CGFloat(layout.inset.bottom)
      scrollView.contentInsets.right = CGFloat(layout.inset.right)
    }

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
    scrollView.contentView.addSubview(tableView)

    component.items.enumerated().forEach {
      component.items[$0.offset].size.width = size.width
    }

    tableView.frame.size = size
    prepareItems()
    tableView.dataSource = spotDataSource
    tableView.delegate = spotDelegate
    tableView.backgroundColor = NSColor.clear
    tableView.allowsColumnReordering = false
    tableView.allowsColumnResizing = false
    tableView.allowsColumnSelection = false
    tableView.allowsEmptySelection = true
    tableView.allowsMultipleSelection = false
    tableView.headerView = nil
    tableView.selectionHighlightStyle = .none
    tableView.allowsTypeSelect = true
    tableView.focusRingType = .none
    tableView.target = self
    tableView.action = #selector(self.action(_:))
    tableView.doubleAction = #selector(self.doubleAction(_:))
    tableView.sizeToFit()

    let column = NSTableColumn(identifier: "tableview-column")
    column.maxWidth = 250
    column.width = 250
    column.minWidth = 150

    tableView.addTableColumn(column)

    headerHeight = configureHeaderFooterComponentKey(.header, with: size)
    footerHeight = configureHeaderFooterComponentKey(.footer, with: size)
  }

  fileprivate func setupCollectionView(_ collectionView: CollectionView, with size: CGSize) {
    scrollView.contentView.addSubview(collectionView)
    collectionView.frame.size = size
    prepareItems()

    collectionView.backgroundColors = [NSColor.clear]
    collectionView.isSelectable = true
    collectionView.allowsMultipleSelection = false
    collectionView.allowsEmptySelection = true
    collectionView.layer = CALayer()
    collectionView.wantsLayer = true
    collectionView.dataSource = spotDataSource
    collectionView.delegate = spotDelegate

    let backgroundView = NSView()
    backgroundView.wantsLayer = true
    collectionView.backgroundView = backgroundView

    headerHeight = configureHeaderFooterComponentKey(.header, with: size)
    footerHeight = configureHeaderFooterComponentKey(.footer, with: size)
    scrollView.frame.size = size

    switch componentKind {
    case .carousel:
      setupHorizontalCollectionView(collectionView, with: size)
    default:
      setupVerticalCollectionView(collectionView, with: size)
    }
  }

  fileprivate func setupHorizontalCollectionView(_ collectionView: CollectionView, with size: CGSize) {
    var newCollectionViewHeight: CGFloat = 0.0

    newCollectionViewHeight <- component.items.sorted(by: {
      $0.size.height > $1.size.height
    }).first?.size.height

    scrollView.scrollingEnabled = (component.items.count > 1)
    scrollView.hasHorizontalScroller = (component.items.count > 1)

    collectionView.frame.size.height = newCollectionViewHeight + headerHeight + footerHeight
    CarouselSpot.configure?(collectionView)
  }

  fileprivate func setupVerticalCollectionView(_ collectionView: CollectionView, with size: CGSize) {
    GridSpot.configure?(collectionView)
  }

  fileprivate func layoutTableView(_ tableView: TableView, with size: CGSize) {
    tableView.sizeToFit()
    scrollView.frame.size.width = size.width
    scrollView.frame.size.height = tableView.frame.height + scrollView.contentInsets.top + scrollView.contentInsets.bottom + headerHeight + footerHeight
  }

  fileprivate func layoutCollectionView(_ collectionView: CollectionView, with size: CGSize) {
    if componentKind == .carousel {
      layoutHorizontalCollectionView(collectionView, with: size)
    } else {
      layoutVerticalCollectionView(collectionView, with: size)
    }
  }

  fileprivate func layoutHorizontalCollectionView(_ collectionView: CollectionView, with size: CGSize) {
    scrollView.frame.size.width = size.width
    scrollView.frame.size.height = collectionView.frame.height + scrollView.contentInsets.top + scrollView.contentInsets.bottom
  }

  fileprivate func layoutVerticalCollectionView(_ collectionView: CollectionView, with size: CGSize) {
    guard let collectionViewLayout = collectionView.collectionViewLayout else {
      return
    }

    collectionViewLayout.prepare()
    collectionViewLayout.invalidateLayout()
    let layoutInsets = EdgeInsets()

    var layoutHeight = collectionViewLayout.collectionViewContentSize.height + layoutInsets.top + layoutInsets.bottom + headerHeight + footerHeight

    if component.items.isEmpty {
      layoutHeight = size.height + layoutInsets.top + layoutInsets.bottom
    }

    scrollView.frame.size.width = size.width - layoutInsets.right
    scrollView.frame.size.height = layoutHeight
    collectionView.frame.size.height = scrollView.frame.size.height - layoutInsets.top + layoutInsets.bottom
    collectionView.frame.size.width = size.width - layoutInsets.right
  }

  func registerDefaultIfNeeded(view: View.Type) {
    guard Configuration.views.storage[Configuration.views.defaultIdentifier] == nil else {
      return
    }

    Configuration.views.defaultItem = Registry.Item.classType(view)
  }

  open func doubleAction(_ sender: Any?) {
    guard let tableView = tableView,
      let item = item(at: tableView.clickedRow) else {
      return
    }
    delegate?.spotable(self, itemSelected: item)
  }

  open func action(_ sender: Any?) {
    guard let tableView = tableView,
      let item = item(at: tableView.clickedRow) else {
        return
    }
    delegate?.spotable(self, itemSelected: item)
  }

  fileprivate static func setupLayout(_ component: Component) -> NSCollectionViewLayout {
    let layout: NSCollectionViewLayout

    switch LayoutType(rawValue: component.meta(Key.layout, Default.defaultLayout)) ?? LayoutType.flow {
    case .grid:
      let gridLayout = NSCollectionViewGridLayout()

      gridLayout.maximumItemSize = CGSize(width: component.meta(Key.gridLayoutMaximumItemWidth, Default.gridLayoutMaximumItemWidth),
                                          height: component.meta(Key.gridLayoutMaximumItemHeight, Default.gridLayoutMaximumItemHeight))
      gridLayout.minimumItemSize = CGSize(width: component.meta(Key.gridLayoutMinimumItemWidth, Default.gridLayoutMinimumItemWidth),
                                          height: component.meta(Key.gridLayoutMinimumItemHeight, Default.gridLayoutMinimumItemHeight))
      layout = gridLayout
    case .left:
      let leftLayout = CollectionViewLeftLayout()
      layout = leftLayout
    default:
      let flowLayout = NSCollectionViewFlowLayout()
      flowLayout.scrollDirection = .vertical
      layout = flowLayout
    }

    return layout
  }

  public func sizeForItem(at indexPath: IndexPath) -> CGSize {
    return CGSize(
      width:  item(at: indexPath)?.size.width  ?? 0.0,
      height: item(at: indexPath)?.size.height ?? 0.0
    )
  }

  fileprivate func configureHeaderFooterComponentKey(_ key: Component.Key, with size: CGSize) -> CGFloat {

    let identifier: String

    switch key {
    case .header:
      guard !component.header.isEmpty else {
        return 0.0
      }
      identifier = component.header
    case .footer:
      guard !component.footer.isEmpty else {
        return 0.0
      }
      identifier = component.footer
    default:
      return 0.0
    }

    guard let view = Configuration.views.make(identifier)?.view as? Componentable else {
      return 0.0
    }

    return view.preferredHeaderHeight
  }

  public func register() {

  }
}
