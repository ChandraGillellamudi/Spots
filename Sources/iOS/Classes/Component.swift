// swiftlint:disable weak_delegate

import UIKit

public class Component: NSObject, ComponentHorizontallyScrollable {

  public static var layout: Layout = Layout(span: 0.0)
  public static var headers: Registry = Registry()
  public static var defaultKind: String = ComponentModel.Kind.grid.string

  open static var configure: ((_ view: View) -> Void)?

  weak public var focusDelegate: ComponentFocusDelegate?
  weak public var delegate: ComponentDelegate?
  weak public var carouselScrollDelegate: CarouselScrollDelegate?

  public var model: ComponentModel
  public var componentKind: ComponentModel.Kind = .list
  public var compositeComponents: [CompositeComponent] = []

  public var configure: ((ItemConfigurable) -> Void)? {
    didSet {
      configureClosureDidChange()
    }
  }

  public var componentDelegate: Delegate?
  public var componentDataSource: DataSource?
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

  public required init(model: ComponentModel, view: ScrollView, kind: ComponentModel.Kind) {
    self.model = model
    self.componentKind = kind
    self.view = view

    super.init()

    if model.layout == nil {
      self.model.layout = GridComponent.layout
    }

    switch kind {
    case .carousel:
      registerDefaultIfNeeded(view: GridComponentCell.self)
    case .grid:
      registerDefaultIfNeeded(view: GridComponentCell.self)
    case .list:
      registerDefaultIfNeeded(view: ListComponentCell.self)
    case .row:
      registerDefaultIfNeeded(view: RowComponentCell.self)
    default:
      break
    }

    Configuration.register(view: CarouselComponentCell.self, identifier: String(describing: CarouselComponentCell.self))
    Configuration.register(view: GridComponentCell.self, identifier: String(describing: GridComponentCell.self))
    Configuration.register(view: ListComponentCell.self, identifier: String(describing: ListComponentCell.self))

    userInterface?.register()

    if let componentLayout = self.model.layout,
      let collectionViewLayout = collectionView?.collectionViewLayout as? GridableLayout {
      componentLayout.configure(collectionViewLayout: collectionViewLayout)
    }

    self.componentDataSource = DataSource(component: self)
    self.componentDelegate = Delegate(component: self)
  }

  public required convenience init(model: ComponentModel) {
    var model = model
    if model.kind.isEmpty {
      model.kind = Component.defaultKind
    }

    let kind = ComponentModel.Kind(rawValue: model.kind) ?? .list
    let view = kind == .list
      ? TableView()
      : CollectionView(frame: CGRect.zero, collectionViewLayout: CollectionLayout())

    self.init(model: model, view: view, kind: kind)
  }

  public convenience init(cacheKey: String) {
    let stateCache = StateCache(key: cacheKey)

    self.init(model: ComponentModel(stateCache.load()))
    self.stateCache = stateCache
  }

  deinit {
    componentDataSource = nil
    componentDelegate = nil
  }

  public func setup(with size: CGSize) {
    type(of: self).configure?(view)

    if let tableView = self.tableView {
      setupTableView(tableView, with: size)
    } else if let collectionView = self.collectionView {
      setupCollectionView(collectionView, with: size)
    }

    layout(with: size)
    configurePageControl()
  }

  public func layout(with size: CGSize) {
    if let tableView = self.tableView {
      layoutTableView(tableView, with: size)
    } else if let collectionView = self.collectionView {
      layoutCollectionView(collectionView, with: size)
    }

    view.layoutSubviews()
  }

  fileprivate func setupCollectionView(_ collectionView: CollectionView, with size: CGSize) {
    collectionView.frame.size = size
    collectionView.dataSource = componentDataSource
    collectionView.delegate = componentDelegate
    collectionView.backgroundView = backgroundView

    if componentKind == .carousel {
      collectionView.showsHorizontalScrollIndicator = false
      self.model.interaction.scrollDirection = .horizontal
    }

    switch model.interaction.scrollDirection {
    case .horizontal:
      setupHorizontalCollectionView(collectionView, with: size)

      if let pageIndicatorPlacement = model.layout?.pageIndicatorPlacement, let layout = collectionView.collectionViewLayout as? FlowLayout {
        switch pageIndicatorPlacement {
        case .below:
          layout.sectionInset.bottom += pageControl.frame.height
          pageControl.frame.origin.y = collectionView.frame.height
        case .overlay:
          let verticalAdjustment = CGFloat(2)
          pageControl.frame.origin.y = collectionView.frame.height - pageControl.frame.height - verticalAdjustment
        }
      }
    case .vertical:
      setupVerticalCollectionView(collectionView, with: size)
    }
  }

  fileprivate func layoutCollectionView(_ collectionView: CollectionView, with size: CGSize) {
    if compositeComponents.isEmpty {
      prepareItems()
    }

    switch model.interaction.scrollDirection {
    case .horizontal:
      layoutHorizontalCollectionView(collectionView, with: size)
    case .vertical:
      layoutVerticalCollectionView(collectionView, with: size)
    }
  }

  func registerDefaultIfNeeded(view: View.Type) {
    guard Configuration.views.defaultItem == nil else {
      return
    }

    Configuration.views.defaultItem = Registry.Item.classType(view)
  }

  func configurePageControl() {
    guard let placement = model.layout?.pageIndicatorPlacement else {
      pageControl.removeFromSuperview()
      return
    }

    pageControl.numberOfPages = model.items.count
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

  public func afterUpdate() {
    setup(with: view.frame.size)
  }

  public func register() {

  }
}
