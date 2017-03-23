import Cocoa

extension NSTableView: UserInterface {

  public var visibleViews: [View] {
    let rows = self.rows(in: visibleRect)
    var views = [View]()

    for row in rows.location..<rows.length-rows.location {
      guard let view = rowView(atRow: row, makeIfNecessary: false) else {
        continue
      }

      views.append(resolveVisibleView(view))
    }

    return views
  }

  public static var compositeIdentifier: String {
    return "list-composite"
  }

  public func register() {}

  public func view<T>(at index: Int) -> T? {
    let view = rowView(atRow: index, makeIfNecessary: true)

    switch view {
    case let view as ListWrapper:
      return view.wrappedView as? T
    default:
      return view as? T
    }
  }

  public func insert(_ indexes: [Int], withAnimation animation: Animation = .automatic, completion: (() -> Void)? = nil) {
    let indexPaths = NSMutableIndexSet()
    indexes.forEach { indexPaths.add($0) }
    performUpdates({ insertRows(at: indexPaths as IndexSet, withAnimation: animation.tableViewAnimation) },
                   endClosure: completion)

  }

  public func reload(_ indexes: [Int], withAnimation animation: Animation = .automatic, completion: (() -> Void)? = nil) {
    guard let component = (dataSource as? DataSource)?.component else {
      return
    }

    /** Manually handle reloading of the cell as reloadDataForRowIndexes does not seems to work with view based table views
     - "For NSView-based table views, this method drops the view-cells in the table row, but not the NSTableRowView instances."
    */

    indexes.forEach { index in
      if let view = rowView(atRow: index, makeIfNecessary: false) as? ItemConfigurable {
        var item = component.model.items[index]
        view.configure(&item)
        component.model.items[index] = item
      }
    }

    completion?()
  }

  public func delete(_ indexes: [Int], withAnimation animation: Animation = .automatic, completion: (() -> Void)? = nil) {
    let indexPaths = NSMutableIndexSet()
    indexes.forEach { indexPaths.add($0) }
    performUpdates({ removeRows(at: indexPaths as IndexSet, withAnimation: animation.tableViewAnimation) },
                   endClosure: completion)
  }

  public func process(_ changes: (insertions: [Int], reloads: [Int], deletions: [Int], childUpdates: [Int]),
                      withAnimation animation: Animation = .automatic,
                      updateDataSource: () -> Void,
                      completion: ((()) -> Void)? = nil) {
    guard let component = (dataSource as? DataSource)?.component else {
      return
    }

    let insertionsSets = NSMutableIndexSet()
    changes.insertions.forEach { insertionsSets.add($0) }
    let reloadSets = NSMutableIndexSet()
    changes.reloads.forEach { reloadSets.add($0) }
    let deletionSets = NSMutableIndexSet()
    changes.deletions.forEach { deletionSets.add($0) }

    updateDataSource()
    beginUpdates()
    removeRows(at: deletionSets as IndexSet, withAnimation: animation.tableViewAnimation)
    insertRows(at: insertionsSets as IndexSet, withAnimation: animation.tableViewAnimation)

    for index in reloadSets {
      guard let view = rowView(atRow: index, makeIfNecessary: false) as? ItemConfigurable else {
        continue
      }

      var item = component.model.items[index]
      view.configure(&item)
      component.model.items[index] = item
    }

    completion?()
    endUpdates()
  }

  public func reloadSection(_ section: Int, withAnimation animation: Animation, completion: (() -> Void)?) {
    reloadData()
    completion?()
  }

  public func reloadDataSource() {
    reloadData()
  }

  fileprivate func performUpdates( _ closure: () -> Void, endClosure: (() -> Void)? = nil) {
    beginUpdates()
    closure()
    endUpdates()
    endClosure?()
  }
}
