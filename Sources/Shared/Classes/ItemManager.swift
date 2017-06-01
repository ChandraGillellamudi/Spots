#if os(macOS)
  import Cocoa
#else
  import UIKit
#endif

public class ItemManager {

  func prepareItems(component: Component, recreateComposites: Bool = true) {
    component.model.items = prepare(component: component, items: component.model.items, recreateComposites: recreateComposites)
    Configuration.views.purge()
  }

  func prepare(component: Component, items: [Item], recreateComposites: Bool) -> [Item] {
    var preparedItems = items
    var spanWidth: CGFloat?

    if component.model.kind == .list {
      spanWidth = component.view.frame.width
    } else if let layout = component.model.layout, layout.span > 0.0 {
      let componentWidth: CGFloat = component.view.frame.size.width - CGFloat(layout.inset.left + layout.inset.right)
      spanWidth = (componentWidth / CGFloat(layout.span)) - CGFloat(layout.itemSpacing)
    }

    preparedItems.enumerated().forEach { (index: Int, item: Item) in
      if let _ = configure(component: component, item: item, at: index, usesViewSize: true, recreateComposites: recreateComposites) {
        preparedItems[index].index = index
      }

      if let spanWidth = spanWidth {
        component.sizeCache.updateOrCreate(.width, value: spanWidth, for: index)
      }
    }

    return preparedItems
  }

  public func configureItem(at index: Int, component: Component, usesViewSize: Bool = false, recreateComposites: Bool = true) {
    guard let item = component.item(at: index),
      let configuredItem = configure(component: component, item: item, at: index, usesViewSize: usesViewSize, recreateComposites: recreateComposites)
      else {
        return
    }

    component.model.items[index] = configuredItem
  }

  @discardableResult func configure(component: Component, item: Item, at index: Int, usesViewSize: Bool = false, recreateComposites: Bool) -> Item? {
    var item = item
    item.index = index

    var fullWidth: CGFloat = item.size.width
    let kind = component.identifier(at: index)

    #if !os(OSX)
      if fullWidth == 0.0 {
        fullWidth = UIScreen.main.bounds.width
      }

      let view: View?

      if let resolvedView = Configuration.views.make(kind, parentFrame: component.view.bounds, useCache: true)?.view {
        view = resolvedView
      } else {
        return nil
      }

      if let view = view {
        view.frame.size.width = component.view.bounds.width
        prepare(component: component, item: item, view: view)
      }

      prepare(component: component, kind: kind, view: view as Any, item: item, recreateComposites: recreateComposites)
    #else
      if fullWidth == 0.0 {
        fullWidth = component.view.superview?.frame.size.width ?? component.view.frame.size.width
      }

      if kind.contains(CompositeComponent.identifier) {
        let wrappable: Wrappable
        if kind.contains("list") {
          wrappable = ListWrapper()
        } else {
          wrappable = GridWrapper()
        }

        prepare(component: component, kind: kind, view: wrappable as Any, item: &item, recreateComposites: recreateComposites)
      } else {
        if let resolvedView = Configuration.views.make(kind, parentFrame: component.view.frame, useCache: true)?.view {
          prepare(component: component, kind: kind, view: resolvedView as Any, item: &item, recreateComposites: recreateComposites)
        } else {
          return nil
        }
      }
    #endif

    return item
  }

  func prepare(component: Component, kind: String, view: Any, item: Item, recreateComposites: Bool) {
    if let view = view as? Wrappable, kind.contains(CompositeComponent.identifier) {
      prepare(component: component, wrappable: view, item: item, recreateComposites: recreateComposites)
    } else if let view = view as? ItemConfigurable {
      view.configure(with: item)
      let size = view.computeSize(for: item)
      component.sizeCache.add(size, for: item.index)
      setFallbackViewSize(component: component, item: item, with: view)
    }
  }

  #if !os(OSX)
  /// Prepare view frame for item
  ///
  /// - parameter view: The view that is going to be prepared.
  func prepare(component: Component, item: Item, view: View) {
    // Set initial size for view
    component.view.frame.size.width = view.frame.size.width

    if let itemConfigurable = view as? ItemConfigurable, view.frame.size.height == 0.0 {
      let size = itemConfigurable.computeSize(for: item)
      view.frame.size.height = size.height
      component.sizeCache.updateOrCreate(.height, value: size.height, for: item.index)
    }

    if view.frame.size.width == 0.0 {
      view.frame.size.width = UIScreen.main.bounds.size.width
    }

    (view as? UITableViewCell)?.contentView.frame = view.bounds
    (view as? UICollectionViewCell)?.contentView.frame = view.bounds
  }
  #endif

  /// Prepares a composable view and returns the height for the item
  ///
  /// - parameter composable:        A composable object
  /// - parameter usesViewSize:      A boolean value to determine if the view uses the views height
  ///
  /// - returns: The height for the item based of the composable components
  func prepare(component: Component, wrappable: Wrappable, item: Item, recreateComposites: Bool) {
    var height: CGFloat = 0.0

    if recreateComposites {
      component.compositeComponents.filter({ $0.itemIndex == item.index }).forEach {
        $0.component.view.removeFromSuperview()

        if let index = component.compositeComponents.index(of: $0) {
          component.compositeComponents.remove(at: index)
        }
      }
    }

    let components: [Component] = Parser.parse(item)
    var size = component.view.frame.size

    if let layout = component.model.layout, layout.span > 0.0 {
      let componentWidth: CGFloat = component.view.frame.size.width - CGFloat(layout.inset.left + layout.inset.right)
      size.width = (componentWidth / CGFloat(layout.span)) - CGFloat(layout.itemSpacing)
    }

    size.width = round(size.width)

    components.forEach { childComponent in
      let compositeSpot = CompositeComponent(component: childComponent,
                                             itemIndex: item.index)
      compositeSpot.component.parentComponent = component
      compositeSpot.component.setup(with: size)

      #if !os(OSX)
        /// Disable scrolling for listable objects
        compositeSpot.component.view.isScrollEnabled = !(compositeSpot.component.view is TableView)
      #endif

      height += compositeSpot.component.computedHeight

      if recreateComposites {
        component.compositeComponents.append(compositeSpot)
      }
    }

    component.sizeCache.updateOrCreate(.height, value: height, for: item.index)
  }

  /// Set fallback size to view
  ///
  /// - Parameters:
  ///   - item: The item struct that is being configured.
  ///   - view: The view used for fallback size for the item.
  private func setFallbackViewSize(component: Component, item: Item, with view: ItemConfigurable) {
    let hasExplicitWidth: Bool = item.size.width == 0.0
    let hasExplicitHeight: Bool = item.size.height == 0.0

    if !hasExplicitWidth && !hasExplicitHeight {
      component.sizeCache.add(item.size, for: item.index)
      return
    }

    let size = view.computeSize(for: item)

    if !hasExplicitHeight {
      component.sizeCache.updateOrCreate(.height, value: size.height, for: item.index)
    }

    if !hasExplicitWidth {
      component.sizeCache.updateOrCreate(.width, value: size.width, for: item.index)
    }

    if let superview = component.view.superview, component.sizeCache.size(at: item.index).width == 0.0 {
      component.sizeCache.updateOrCreate(.width, value: superview.frame.width, for: item.index)
    }

    if let view = view as? View, component.sizeCache.size(at: item.index).width == 0.0 || item.size.width > view.bounds.width {
      component.sizeCache.updateOrCreate(.width, value: view.bounds.width, for: item.index)
    }
  }
}
