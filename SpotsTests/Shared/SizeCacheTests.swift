@testable import Spots
import Foundation
import XCTest

class SizeCacheTests: XCTestCase {

  var component: Component!

  override func setUp() {
    super.setUp()

    let items = (0..<3).flatMap({ Item(title: "Item: \($0)", kind: "test") })
    let model = ComponentModel(kind: .list,items: items)
    component = Component(model: model)
    component.setup(with: CGSize(width: 100, height: 100))

    Configuration.register(view: TestView.self, identifier: "test")
    Configuration.views.purge()
  }

  func testSizeCacheUpdateWidthOrCreate() {
    let cache = SizeCache()

    cache.updateOrCreate(.width, value: 100, for: 0)
    XCTAssertEqual(cache.sizes[0], CGSize(width: 100, height: 0))
    cache.updateOrCreate(.height, value: 100, for: 0)
    XCTAssertEqual(cache.sizes[0], CGSize(width: 100, height: 100))

    XCTAssertEqual(cache.sizes.count, 1)
  }

  func testSizeCacheTotalHeight() {
    let computedHeight = component.computedHeight
    let sizeCacheHeight = component.sizeCache.totalHeight()

    XCTAssertEqual(computedHeight, sizeCacheHeight)
  }
}
