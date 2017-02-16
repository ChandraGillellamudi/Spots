@testable import Spots
#if os(OSX)
import Foundation
#else
import UIKit
#endif

import Tailor

struct Meta {
  var id = 0
  var name: String?
}

extension Meta: Mappable {

  init(_ map: [String : Any]) {
    id = map.property("id") ?? 0
    name = map.property("name") ?? ""
  }
}

extension Controller {

  func prepareController() {
    preloadView()
    viewDidAppear()
    spots.forEach {
      $0.view.layoutSubviews()
    }
  }

  func preloadView() {
    let _ = view
    #if os(OSX)
      view.frame.size = CGSize(width: 100, height: 100)
    #endif
  }
  #if !os(OSX)
  func viewDidAppear() {
    viewWillAppear(true)
    viewDidAppear(true)
  }
  #endif

  func scrollTo(_ point: CGPoint) {
    #if !os(OSX)
    scrollView.setContentOffset(point, animated: false)
    scrollView.layoutSubviews()
    #endif
  }
}

#if !os(OSX)

#endif

class TestView: View, ItemConfigurable {
  var preferredViewSize: CGSize = CGSize(width: 50, height: 50)

  func configure(_ item: inout Item) {

  }
}
