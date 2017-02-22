@testable import Spots
import XCTest

class TestSpot: XCTestCase {

  override func setUp() {
    Configuration.views.storage = [:]
    Configuration.views.defaultItem = nil
    Configuration.register(view: HeaderView.self, identifier: "Header")
    Configuration.register(view: TextView.self, identifier: "TextView")
    Configuration.register(view: FooterView.self, identifier: "Footer")
  }

  func testDefaultValues() {
    let items = [Item(title: "A"), Item(title: "B")]
    let component = Component(items: items, hybrid: true)
    let spot = Spot(component: component)

    spot.setup(CGSize(width: 100, height: 100))

    XCTAssertTrue(spot.view is TableView)
    XCTAssertTrue(spot.view.isEqual(spot.tableView))
    XCTAssertEqual(spot.items[0].size, CGSize(width: 100, height: 44))
    XCTAssertEqual(spot.items[1].size, CGSize(width: 100, height: 44))
    XCTAssertEqual(spot.view.frame.size, CGSize(width: 100, height: 100))

    /// tvOS adds 14 pixels to each item in a table view.
    /// So for tvOS, the calculation would look like this:
    /// let contentSize.height = item.reduce(0, { $0 + $1.item.size.height + 14 })
    #if os(tvOS)
      let expectedContentSizeHeight: CGFloat = 116
    #elseif os(iOS)
      let expectedContentSizeHeight: CGFloat = 88
    #endif
    XCTAssertEqual(spot.view.contentSize, CGSize(width: 100, height: expectedContentSizeHeight))
  }

  func testSpotCache() {
    let item = Item(title: "test")
    let spot = Spot(cacheKey: "test-spot-cache")

    XCTAssertEqual(spot.component.items.count, 0)
    spot.append(item) {
      spot.cache()
    }

    let expectation = self.expectation(description: "Wait for cache")
    Dispatch.after(seconds: 2.5) {
      guard let cacheKey = spot.stateCache?.key else {
        XCTFail()
        return
      }

      let cachedSpot = Spot(cacheKey: cacheKey)
      XCTAssertEqual(cachedSpot.component.items[0].title, "test")
      XCTAssertEqual(cachedSpot.component.items.count, 1)
      cachedSpot.stateCache?.clear()
      expectation.fulfill()

      cachedSpot.stateCache?.clear()
    }
    waitForExpectations(timeout: 10.0, handler: nil)
  }

  func testCompareHybridListSpotWithCoreType() {
    let items = [Item(title: "A"), Item(title: "B")]
    let component = Component(kind: Component.Kind.list.string, items: items, hybrid: true)
    let listComponent = Component(kind: Component.Kind.list.string, items: items)
    let spot = Spot(component: component)
    let listSpot = ListSpot(component: listComponent)

    XCTAssertTrue(type(of: spot.view) == type(of: listSpot.view))

    spot.setup(CGSize(width: 100, height: 100))
    listSpot.setup(CGSize(width: 100, height: 100))
    listSpot.layout(CGSize(width: 100, height: 100))
    listSpot.view.layoutSubviews()

    XCTAssertEqual(spot.component.interaction.scrollDirection, listSpot.component.interaction.scrollDirection)
    XCTAssertEqual(spot.items[0].size, listSpot.items[0].size)
    XCTAssertEqual(spot.items[1].size, listSpot.items[0].size)
    XCTAssertEqual(spot.sizeForItem(at: IndexPath(item: 0, section: 0)), listSpot.sizeForItem(at: IndexPath(item: 0, section: 0)))
    XCTAssertEqual(spot.sizeForItem(at: IndexPath(item: 1, section: 0)), listSpot.sizeForItem(at: IndexPath(item: 1, section: 0)))
    XCTAssertEqual(spot.view.frame, listSpot.view.frame)
    XCTAssertEqual(spot.view.contentSize, listSpot.view.contentSize)
  }

  func testCompareHybridGridSpotWithCoreType() {
    let items = [Item(title: "A"), Item(title: "B")]
    let component = Component(kind: Component.Kind.grid.string, items: items, hybrid: true)
    let gridComponent = Component(kind: Component.Kind.grid.string, items: items)
    let spot = Spot(component: component)
    let gridSpot = GridSpot(component: gridComponent)

    XCTAssertTrue(type(of: spot.view) == type(of: gridSpot.view))

    spot.setup(CGSize(width: 100, height: 100))
    gridSpot.setup(CGSize(width: 100, height: 100))
    gridSpot.layout(CGSize(width: 100, height: 100))
    gridSpot.view.layoutSubviews()

    XCTAssertEqual(spot.component.interaction.scrollDirection, gridSpot.component.interaction.scrollDirection)
    XCTAssertEqual(spot.items[0].size, gridSpot.items[0].size)
    XCTAssertEqual(spot.items[1].size, gridSpot.items[0].size)
    XCTAssertEqual(spot.sizeForItem(at: IndexPath(item: 0, section: 0)), gridSpot.sizeForItem(at: IndexPath(item: 0, section: 0)))
    XCTAssertEqual(spot.sizeForItem(at: IndexPath(item: 1, section: 0)), gridSpot.sizeForItem(at: IndexPath(item: 1, section: 0)))
    XCTAssertEqual(spot.view.frame, gridSpot.view.frame)
    XCTAssertEqual(spot.view.contentSize, gridSpot.view.contentSize)
  }

  func testCompareHybridCarouselSpotWithCoreType() {
    let items = [Item(title: "A"), Item(title: "B")]
    let component = Component(kind: Component.Kind.carousel.string, items: items, hybrid: true)
    let carouselComponent = Component(kind: Component.Kind.carousel.string, items: items)
    let spot = Spot(component: component)
    let carouselSpot = CarouselSpot(component: carouselComponent)

    XCTAssertTrue(type(of: spot.view) == type(of: carouselSpot.view))

    spot.setup(CGSize(width: 100, height: 100))
    carouselSpot.setup(CGSize(width: 100, height: 100))
    carouselSpot.layout(CGSize(width: 100, height: 100))
    carouselSpot.view.layoutSubviews()

    XCTAssertEqual(spot.component.interaction.scrollDirection, carouselSpot.component.interaction.scrollDirection)
    XCTAssertEqual(spot.items[0].size, carouselSpot.items[0].size)
    XCTAssertEqual(spot.items[1].size, carouselSpot.items[0].size)
    XCTAssertEqual(spot.sizeForItem(at: IndexPath(item: 0, section: 0)), carouselSpot.sizeForItem(at: IndexPath(item: 0, section: 0)))
    XCTAssertEqual(spot.sizeForItem(at: IndexPath(item: 1, section: 0)), carouselSpot.sizeForItem(at: IndexPath(item: 1, section: 0)))
    XCTAssertEqual(spot.view.frame, carouselSpot.view.frame)
    XCTAssertEqual(spot.view.contentSize, carouselSpot.view.contentSize)
  }

  func testHybridListSpotWithHeaderAndFooter() {
    let component = Component(
      header: "Header",
      footer: "Footer",
      kind: Component.Kind.list.string,
      items: [
        Item(title: "A"),
        Item(title: "B"),
        Item(title: "C"),
        Item(title: "D")
      ],
      hybrid: true
    )
    let spot = Spot(component: component)
    spot.setup(CGSize(width: 100, height: 100))

    XCTAssertEqual(spot.view.frame.size, CGSize(width: 100, height: 100))

    /// tvOS adds 14 pixels to each item in a table view.
    /// So for tvOS, the calculation would look like this:
    /// let contentSize.height = item.reduce(0, { $0 + $1.item.size.height + 14 })
    #if os(tvOS)
      let expectedContentSizeHeight: CGFloat = 332
    #elseif os(iOS)
      let expectedContentSizeHeight: CGFloat = 276
    #endif
    XCTAssertEqual(spot.view.contentSize, CGSize(width: 100, height: expectedContentSizeHeight))
  }

  func testHybridCarouselSpotWithHeaderAndFooter() {
    let component = Component(
      header: "Header",
      footer: "Footer",
      kind: Component.Kind.carousel.string,
      items: [
        Item(title: "A"),
        Item(title: "B"),
        Item(title: "C"),
        Item(title: "D")
      ],
      hybrid: true
    )
    let spot = Spot(component: component)
    spot.setup(CGSize(width: 100, height: 100))

    XCTAssertEqual(spot.view.frame.size, CGSize(width: 100, height: 188))
    XCTAssertEqual(spot.view.contentSize, CGSize(width: 352, height: 188))
  }

  func testPaginatedHybridCarouselSnapping() {
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
      "hybrid" : true,
      "interaction": Interaction(paginate: .item).dictionary,
      "kind" : Component.Kind.carousel.rawValue,
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

    let component = Component(json)
    let spot = Spot(component: component, view: collectionView, kind: .carousel)
    let parentSize = CGSize(width: 300, height: 100)

    spot.setup(parentSize)
    spot.view.layoutSubviews()

    // Make sure our mocked item size is correct
    XCTAssertEqual(collectionView.itemSize, spot.items[0].size)

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
}
