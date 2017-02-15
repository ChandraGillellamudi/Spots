public protocol Wrappable: class {

  var frame: CGRect { get }
  var bounds: CGRect { get }
  var contentView: View { get }
  var wrappedView: View? { get set }

  func configure(with view: View)
  func configureWrappedView()
}
