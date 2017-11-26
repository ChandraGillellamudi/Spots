@testable import Spots
import XCTest

class ComponentControllerTests: XCTestCase {

  class MockedComponentController: ComponentController {
    var didUpdateInvocation: Int = 0
    var didScrollInvocation: Int = 0

    var component: Component

    required init(component: Component) {
      self.component = component
    }

    func componentDidUpdate(_ component: Component) {
      didUpdateInvocation += 1
    }

    func componentDidScroll(_ component: Component) {
      didScrollInvocation += 1
    }
  }

  func testComponentContorllerRegistration() {
    let configuration = Configuration()
    configuration.register(controller: MockedComponentController.self, identifier: "Mock")
    XCTAssertNotNil(configuration.controllers["Mock"])
  }

  func testCreatingComponentController() {
    let configuration = Configuration()
    configuration.register(controller: MockedComponentController.self, identifier: "Mock")
    let component = Component(model: ComponentModel(controller: "Mock"), configuration: configuration)
    XCTAssertTrue(component.controller is MockedComponentController)
  }

  func testComponentDidUpdate() {
    let configuration = Configuration()
    configuration.register(controller: MockedComponentController.self, identifier: "Mock")
    let component = Component(model: ComponentModel(controller: "Mock"), configuration: configuration)
    let exception = self.expectation(description: "Wait for append to finish.")
    component.append(Item()) {
      XCTAssertEqual((component.controller as? MockedComponentController)?.didUpdateInvocation, 1)
      exception.fulfill()
    }
    waitForExpectations(timeout: 10.0, handler: nil)
  }

    func testcomponentdidscroll() {
      let configuration = Configuration()
      configuration.register(controller: MockedComponentController.self, identifier: "Mock")
      let component = Component(model: ComponentModel(controller: "Mock"), configuration: configuration)
      component.setup(with: .init(width: 200, height: 200))
      component.view.setContentOffset(.init(x: 0, y: 100), animated: true)

      XCTAssertEqual((component.controller as? MockedComponentController)?.didScrollInvocation, 1)
    }
}
