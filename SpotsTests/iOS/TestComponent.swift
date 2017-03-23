@testable import Spots
import Foundation
import XCTest

class ComponentTests: XCTestCase {

  var component: CarouselComponent!
  var cachedSpot: CarouselComponent!

  override func setUp() {
    component = CarouselComponent(model: ComponentModel(span: 1.0))
    cachedSpot = CarouselComponent(cacheKey: "cached-carousel-component")
    XCTAssertNotNil(cachedSpot.stateCache)
    cachedSpot.stateCache?.clear()
  }

  override func tearDown() {
    component = nil
    cachedSpot = nil
  }

  func testConvenienceInitWithSectionInsets() {
    let layout = Layout(itemSpacing: 5, inset: Inset(top: 5, left: 10, bottom: 5, right: 5))
    let model = ComponentModel(kind: .grid, layout: layout, span: 1.0)
    let component = CarouselComponent(model: model)

    guard let collectionViewLayout = component.collectionView?.collectionViewLayout as? UICollectionViewFlowLayout else {
      XCTFail("Unable to resolve collection view layout")
      return
    }

    XCTAssertEqual(collectionViewLayout.sectionInset, UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 5))
    XCTAssertEqual(collectionViewLayout.minimumInteritemSpacing, 5)
  }

  func testDictionaryRepresentation() {
    let model = ComponentModel(title: "CarouselComponent", kind: .carousel, span: 3, meta: ["headerHeight": 44.0])
    let component = CarouselComponent(model: model)
    XCTAssertEqual(model.dictionary["index"] as? Int, component.dictionary["index"] as? Int)
    XCTAssertEqual(model.dictionary["title"] as? String, component.dictionary["title"] as? String)
    XCTAssertEqual(model.dictionary["kind"] as? String, component.dictionary["kind"] as? String)
    XCTAssertEqual(model.dictionary["span"] as? Int, component.dictionary["span"] as? Int)
    XCTAssertEqual(
      (model.dictionary["meta"] as! [String : Any])["headerHeight"] as? CGFloat,
      (component.dictionary["meta"] as! [String : Any])["headerHeight"] as? CGFloat
    )
  }

  func testSafelyResolveKind() {
    let model = ComponentModel(title: "CarouselComponent", kind: .carousel, span: 1.0, items: [Item(title: "foo", kind: "custom-item-kind")])
    let carouselComponent = CarouselComponent(model: model)
    let indexPath = IndexPath(row: 0, section: 0)

    XCTAssertEqual(carouselComponent.identifier(for: indexPath), Configuration.views.defaultIdentifier)

    Configuration.views.defaultItem = Registry.Item.classType(CarouselComponentCell.self)
    XCTAssertEqual(carouselComponent.identifier(for: indexPath), Configuration.views.defaultIdentifier)

    Configuration.views.defaultItem = Registry.Item.classType(CarouselComponentCell.self)
    XCTAssertEqual(carouselComponent.identifier(for: indexPath), Configuration.views.defaultIdentifier)

    Configuration.views["custom-item-kind"] = Registry.Item.classType(CarouselComponentCell.self)
    XCTAssertEqual(carouselComponent.identifier(for: indexPath), "custom-item-kind")
  }

  func testCarouselSetupWithSimpleStructure() {
    let json: [String : Any] = [
      "kind" : "carousel",
      "items": [
        ["title": "foo",
          "size": [
            "width": 120.0,
            "height": 180.0]
        ],
        ["title": "bar",
          "size": [
            "width": 120.0,
            "height": 180.0]
        ],
        ["title": "baz",
          "size": [
            "width": 120,
            "height": 180]
        ],
      ],
      "meta": [
        "item-spacing": 25.0,
        "line-spacing": 10.0
      ]
    ]

    let model = ComponentModel(json)
    let component = CarouselComponent(model: model)
    component.setup(with: CGSize(width: 100, height: 100))

    guard let collectionView = component.collectionView else {
      XCTFail("Unable to resolve collection view.")
      return
    }

    guard let collectionViewLayout = collectionView.collectionViewLayout as? FlowLayout  else {
      XCTFail("Unable to resolve collection view layout.")
      return
    }

    // Test that component height is equal to first item in the list
    XCTAssertEqual(component.model.items.count, 3)
    XCTAssertEqual(component.model.items[0].title, "foo")
    XCTAssertEqual(component.model.items[1].title, "bar")
    XCTAssertEqual(component.model.items[2].title, "baz")
    XCTAssertEqual(component.model.items.first?.size.width, 120)
    XCTAssertEqual(component.model.items.first?.size.height, 180)
    XCTAssertEqual(component.view.frame.size.height, 180)

    // Check default value of `paginate`
    XCTAssertFalse(collectionView.isPagingEnabled)

    // Check that header height gets added to the calculation
    collectionViewLayout.headerReferenceSize.height = 20
    component.setup(with: CGSize(width: 100, height: 100))
    XCTAssertEqual(component.view.frame.size.height, 200)
  }

  func testCarouselSetupWithPagination() {
    Configuration.registerDefault(view: GridComponentCell.self)

    let json: [String : Any] = [
      "kind" : "carousel",
      "items": [
        ["title": "foo", "kind": "carousel"],
        ["title": "bar", "kind": "carousel"],
        ["title": "baz", "kind": "carousel"],
        ["title": "bazar", "kind": "carousel"]
      ],
      "interaction": Interaction(paginate: .page).dictionary,
      "layout": Layout(
        span: 4.0,
        dynamicSpan: false,
        pageIndicatorPlacement: .below
      ).dictionary
    ]

    let model = ComponentModel(json)
    let component = CarouselComponent(model: model)
    let parentSize = CGSize(width: 667, height: 225)

    // Check `span` mapping
    XCTAssertEqual(component.model.layout!.span, 4.0)

    component.setup(with: parentSize)
    component.prepareItems()
    component.view.layoutSubviews()

    let width = component.view.bounds.width / 4

    // Test that component height is equal to first item in the list
    XCTAssertEqual(component.model.items.count, 4)
    XCTAssertEqual(component.model.items[0].title, "foo")
    XCTAssertEqual(component.model.items[1].title, "bar")
    XCTAssertEqual(component.model.items[2].title, "baz")
    XCTAssertEqual(component.model.items[3].title, "bazar")
    XCTAssertEqual(component.model.items[0].size.width, width)
    XCTAssertEqual(component.model.items[0].size.height, 88)
    XCTAssertEqual(component.model.items[1].size.width, width)
    XCTAssertEqual(component.model.items[1].size.height, 88)
    XCTAssertEqual(component.model.items[2].size.width, width)
    XCTAssertEqual(component.model.items[2].size.height, 88)
    XCTAssertEqual(component.model.items[3].size.width, width)
    XCTAssertEqual(component.model.items[3].size.height, 88)

    // Assert that height has been added for the page indicator
    XCTAssertEqual(component.view.frame.size.height, 110)
    XCTAssertEqual(component.view.contentSize.height, 110)

    guard let collectionViewLayout = component.collectionView?.collectionViewLayout as? FlowLayout else {
      XCTFail("Unable to resolve collection view layout.")
      return
    }

    // Check that header height gets added to the calculation
    collectionViewLayout.headerReferenceSize.height = 20
    component.setup(with: CGSize(width: 667, height: 225))
    component.layout(with: CGSize(width: 667, height: 225))
    component.view.layoutSubviews()
    XCTAssertEqual(component.view.frame.size.height, 130)
    XCTAssertEqual(component.view.contentSize.height, 130)
  }

  func testPageIndicatorOverlayPlacement() {
    Configuration.registerDefault(view: GridComponentCell.self)
    let json: [String : Any] = [
      "items": [
        ["title": "foo", "kind": "carousel"],
        ["title": "bar", "kind": "carousel"],
        ["title": "baz", "kind": "carousel"],
        ["title": "bazar", "kind": "carousel"]
      ],
      "kind" : "carousel",
      "interaction": Interaction(paginate: .page).dictionary,
      "layout": Layout(
        span: 4.0,
        dynamicSpan: false,
        pageIndicatorPlacement: .overlay
      ).dictionary
    ]

    let model = ComponentModel(json)
    let component = CarouselComponent(model: model)
    let parentSize = CGSize(width: 667, height: 225)

    component.setup(with: parentSize)
    component.layout(with: parentSize)
    component.prepareItems()
    component.view.layoutSubviews()

    // Sanity check, to make sure we have our page indicator in overlay mode
    XCTAssertEqual(model.layout!.pageIndicatorPlacement, .overlay)

    // Assert item layout (derived from preferred view size)
    XCTAssertEqual(component.model.items[0].size.height, 88)
    XCTAssertEqual(component.model.items[1].size.height, 88)
    XCTAssertEqual(component.model.items[2].size.height, 88)
    XCTAssertEqual(component.model.items[3].size.height, 88)

    // Assert that no height has been added for a page indicator
    XCTAssertEqual(component.view.frame.height, 88)
  }

  func testPaginatedCarouselSnapping() {
    class CollectionViewMock: UICollectionView {
      var itemSize = CGSize.zero

      override func indexPathForItem(at point: CGPoint) -> IndexPath? {
        return IndexPath(item: Int(point.x / itemSize.width), section: 0)
      }
    }

    let json: [String : Any] = [
      "items": [
        [
          "title": "title",
          "kind": "carousel",
          "size": [
            "width": 200.0,
            "height": 100.0
          ]
        ],
        [
          "title": "title",
          "kind": "carousel",
          "size": [
            "width": 200.0,
            "height": 100.0
          ]
        ],
        [
          "title": "title",
          "kind": "carousel",
          "size": [
            "width": 200.0,
            "height": 100.0
          ]
        ],
        [
          "title": "title",
          "kind": "carousel",
          "size": [
            "width": 200.0,
            "height": 100.0
          ]
        ]
      ],
      "kind" : "carousel",
      "interaction": Interaction(paginate: .item).dictionary,
      "layout": Layout(
        span: 0,
        dynamicSpan: false,
        pageIndicatorPlacement: .below,
        itemSpacing: 0
      ).dictionary
    ]

    let layout = CollectionLayout()
    let collectionView = CollectionViewMock(frame: .zero, collectionViewLayout: layout)
    collectionView.itemSize = CGSize(width: 200, height: 100)

    let model = ComponentModel(json)
    let component = CarouselComponent(model: model, view: collectionView, kind: .carousel)
    let parentSize = CGSize(width: 300, height: 100)

    component.setup(with: parentSize)
    component.collectionView?.collectionViewLayout = layout
    component.view.layoutSubviews()

    // Make sure our mocked item size is correct
    XCTAssertEqual(collectionView.itemSize, component.model.items[0].size)

    // When scrolling, make sure the closest item is centered
    var originalPoint = CGPoint(x: 350, y: 0)
    let targetContentOffset = UnsafeMutablePointer(mutating: &originalPoint)
    collectionView.delegate!.scrollViewWillEndDragging!(collectionView, withVelocity: .zero, targetContentOffset: targetContentOffset)
    XCTAssertEqual(targetContentOffset.pointee.x, 350)

    // When scrolling back to origin, no centering should occur
    targetContentOffset.pointee.x = 0
    collectionView.delegate!.scrollViewWillEndDragging!(collectionView, withVelocity: .zero, targetContentOffset: targetContentOffset)
    XCTAssertEqual(targetContentOffset.pointee.x, 0)

    // Make sure an out of bounds content offset is not manipulated
    targetContentOffset.pointee.x = 100000
    targetContentOffset.pointee.y = 100000
    collectionView.delegate!.scrollViewWillEndDragging!(collectionView, withVelocity: .zero, targetContentOffset: targetContentOffset)
    XCTAssertEqual(targetContentOffset.pointee.x, 100000)
    XCTAssertEqual(targetContentOffset.pointee.y, 100000)
  }

  func testAppendItem() {
    let item = Item(title: "test")
    let component = CarouselComponent(model: ComponentModel(span: 1))
    let expectation = self.expectation(description: "Append item")
    component.append(item) {
      XCTAssert(component.model.items.first! == item)
      expectation.fulfill()
    }
    waitForExpectations(timeout: 10.0, handler: nil)
  }

  func testAppendItems() {
    let items = [Item(title: "test"), Item(title: "test 2")]
    let component = CarouselComponent(model: ComponentModel(span: 1))
    let expectation = self.expectation(description: "Append items")
    component.append(items) {
      XCTAssert(component.model.items == items)
      expectation.fulfill()
    }
    waitForExpectations(timeout: 10.0, handler: nil)
  }

  func testInsertItem() {
    let item = Item(title: "test")
    let component = CarouselComponent(model: ComponentModel(span: 1))
    let expectation = self.expectation(description: "Insert item")
    component.insert(item, index: 0) {
      XCTAssert(component.model.items.first! == item)
      expectation.fulfill()
    }
    waitForExpectations(timeout: 10.0, handler: nil)
  }

  func testPrependItems() {
    let items = [Item(title: "test"), Item(title: "test 2")]
    let component = CarouselComponent(model: ComponentModel(span: 1))
    let expectation = self.expectation(description: "Prepend items")
    component.prepend(items) {
      XCTAssert(component.model.items == items)
      expectation.fulfill()
    }
    waitForExpectations(timeout: 10.0, handler: nil)
  }

  func testSpotCache() {
    let item = Item(title: "test")

    XCTAssertEqual(cachedSpot.model.items.count, 0)
    cachedSpot.append(item) {
      self.cachedSpot.cache()
    }

    let expectation = self.expectation(description: "Wait for cache")
    Dispatch.after(seconds: 0.25) { [weak self] in
      guard let strongSelf = self else { return }
      let cachedSpot = CarouselComponent(cacheKey: strongSelf.cachedSpot.stateCache!.key)
      XCTAssertEqual(cachedSpot.model.items.count, 1)
      cachedSpot.stateCache?.clear()
      expectation.fulfill()
    }
    waitForExpectations(timeout: 10.0, handler: nil)
  }
}
