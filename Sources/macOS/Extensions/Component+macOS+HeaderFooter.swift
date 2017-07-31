import Cocoa

class TableHeaderView: NSTableHeaderView {
  override var isFlipped: Bool { return true }
}

extension Component {

  func setupHeader(with model: inout ComponentModel) {
    guard let header = model.header, headerView == nil else {
      return
    }

    if let (_, headerView) = Configuration.views.make(header.kind) {
      if let headerView = headerView,
        let itemConfigurable = headerView as? ItemConfigurable {
        itemConfigurable.configure(with: header)
        let size = CGSize(width: view.frame.width,
                          height: itemConfigurable.computeSize(for: header, containerSize: view.frame.size).height)
        headerView.frame.size = size
        model.header = header
        self.headerView = headerView

        if model.kind == .list {
          let tableHeaderView = TableHeaderView()
          tableHeaderView.wantsLayer = true
          tableHeaderView.frame.size = headerView.frame.size
          tableHeaderView.addSubview(headerView)
          tableView?.headerView = tableHeaderView
        } else if let collectionView = collectionView {
//          scrollView.addSubview(headerView)
        }
      }
    }
  }

  func setupFooter(with model: inout ComponentModel) {
    guard let footer = model.footer, footerView == nil else {
      return
    }

    if let (_, footerView) = Configuration.views.make(footer.kind) {
      if let footerView = footerView,
        let itemConfigurable = footerView as? ItemConfigurable {
        itemConfigurable.configure(with: footer)
        let size = CGSize(width: view.frame.width,
                          height: itemConfigurable.computeSize(for: footer, containerSize: view.frame.size).height)
        footerView.frame.size = size
        model.footer = footer
        self.footerView = footerView
        scrollView.addSubview(footerView)
      }
    }
  }

  func layoutHeaderFooterViews(_ size: CGSize) {
    headerView?.frame.origin.y = 0.0
    headerView?.frame.size.width = size.width
    footerView?.frame.size.width = size.width
    footerView?.frame.origin.y = scrollView.frame.height - footerHeight
  }
}
