import XCTest
@testable import Spots

#if os(macOS)
  typealias ListView = NSTableRowView
  typealias GridView = NSView
#else
  typealias ListView = UITableViewCell
  typealias GridView = UICollectionViewCell
#endif

class WrappedViewMock: View, ItemConfigurable {

  func configure(with item: Item) {}

  func computeSize(for item: Item) -> CGSize {
    return CGSize(width: 200, height: 200)
  }
}

class ListViewMock: ListView, ItemConfigurable {

  func configure(with item: Item) {}

  func computeSize(for item: Item) -> CGSize {
    return CGSize(width: 300, height: 300)
  }
}

class GridViewMock: GridView, ItemConfigurable {

  func configure(with item: Item) {}

  func computeSize(for item: Item) -> CGSize {
    return CGSize(width: 150, height: 150)
  }
}


class ItemConfigurableComputeSizeTests: XCTestCase {

  enum Identifier: String {
    case wrapped, list, grid

    var identifier: String {
      return "\(String(describing: ItemConfigurableComputeSizeTests.self))-\(self.rawValue)"
    }
  }

  override func setUp() {
    Configuration.register(view: WrappedViewMock.self, identifier: Identifier.wrapped.identifier)
    Configuration.register(view: ListViewMock.self, identifier: Identifier.list.identifier)
    Configuration.register(view: GridViewMock.self, identifier: Identifier.grid.identifier)
  }

  func testWrappedDynamicViewInGrid() {
    let component = createComponent(kind: .grid, items: [Item(kind: Identifier.wrapped.identifier)])
    XCTAssertEqual(component.sizeCache.size(at: 0), CGSize(width: 200, height: 200))
  }

  func testWrappedDynamicViewInList() {
    let component = createComponent(kind: .list, items: [Item(kind: Identifier.wrapped.identifier)])
    XCTAssertEqual(component.sizeCache.size(at: 0), CGSize(width: 200, height: 200))
  }

  func testDynamicListView() {
    let component = createComponent(kind: .list, items: [Item(kind: Identifier.list.identifier)])
    XCTAssertEqual(component.sizeCache.size(at: 0), CGSize(width: 200, height: 300))

    let type: ListViewMock? = component.ui(at: 0)
    XCTAssertNotNil(type)
    let expectation = self.expectation(description: "Wait for component update")
    component.update(Item(kind: Identifier.wrapped.identifier), index: 0) {
      XCTAssertEqual(component.model.items[0].kind, Identifier.wrapped.identifier)
      XCTAssertEqual(component.sizeCache.size(at: 0), CGSize(width: 200, height: 200))
      let type: WrappedViewMock? = component.ui(at: 0)
      XCTAssertNotNil(type)
      expectation.fulfill()
    }

    waitForExpectations(timeout: 10.0, handler: nil)
  }

  func testDynamicGridView() {
    let component = createComponent(kind: .grid, items: [Item(kind: Identifier.grid.identifier)])
    XCTAssertEqual(component.sizeCache.size(at: 0), CGSize(width: 150, height: 150))

    let expectation = self.expectation(description: "Wait for component update")
    component.update(Item(kind: Identifier.wrapped.identifier), index: 0) {
      XCTAssertEqual(component.model.items[0].kind, Identifier.wrapped.identifier)
      XCTAssertEqual(component.sizeCache.size(at: 0), CGSize(width: 200, height: 200))
      let type: WrappedViewMock? = component.ui(at: 0)
      XCTAssertNotNil(type)
      expectation.fulfill()
    }

    waitForExpectations(timeout: 10.0, handler: nil)
  }

  private func createComponent(kind: ComponentKind, items: [Item]) -> Component {
    let model = ComponentModel(kind: kind, items: items)
    let component = Component(model: model)
    component.setup(with: .init(width: 200, height: 200))
    return component
  }
}
