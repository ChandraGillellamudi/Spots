import UIKit

class HeaderView: View, ItemConfigurable, Componentable {

  public var preferredHeaderHeight: CGFloat = 50.0

  var preferredViewSize: CGSize = CGSize(width: 200, height: 50)

  lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.textAlignment = .center
    return label
  }()

  override init(frame: CGRect) {
    super.init(frame: frame)
    addSubview(titleLabel)

    configureConstraints()
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configureConstraints() {
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.heightAnchor.constraint(equalToConstant: 50).isActive = true
    titleLabel.leftAnchor.constraint(equalTo: titleLabel.superview!.leftAnchor).isActive = true
    titleLabel.rightAnchor.constraint(equalTo: titleLabel.superview!.rightAnchor).isActive = true
    titleLabel.centerYAnchor.constraint(equalTo: titleLabel.superview!.centerYAnchor).isActive = true
  }

  func configure(_ item: inout Item) {
    titleLabel.text = item.title
  }

  func configure(_ component: Component) {
    titleLabel.text = component.title
  }
}

class FooterView: View, ItemConfigurable, Componentable {

  var preferredHeaderHeight: CGFloat = 50

  var preferredViewSize: CGSize = CGSize(width: 200, height: 50)

  lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.textAlignment = .center
    return label
  }()

  override init(frame: CGRect) {
    super.init(frame: frame)
    addSubview(titleLabel)

    configureConstraints()
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configureConstraints() {
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.heightAnchor.constraint(equalToConstant: 50).isActive = true
    titleLabel.leftAnchor.constraint(equalTo: titleLabel.superview!.leftAnchor).isActive = true
    titleLabel.rightAnchor.constraint(equalTo: titleLabel.superview!.rightAnchor).isActive = true
    titleLabel.centerYAnchor.constraint(equalTo: titleLabel.superview!.centerYAnchor).isActive = true
  }

  func configure(_ item: inout Item) {
    titleLabel.text = item.title
  }

  func configure(_ component: Component) {
    titleLabel.text = "This is a footer"
  }
}

class TextView: View, ItemConfigurable {

  var preferredViewSize: CGSize = CGSize(width: 200, height: 50)

  lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.textAlignment = .center
    return label
  }()

  override init(frame: CGRect) {
    super.init(frame: frame)
    addSubview(titleLabel)

    backgroundColor = UIColor.gray.withAlphaComponent(0.25)

    configureConstraints()
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configureConstraints() {
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.heightAnchor.constraint(equalToConstant: 50).isActive = true
    titleLabel.leftAnchor.constraint(equalTo: titleLabel.superview!.leftAnchor).isActive = true
    titleLabel.rightAnchor.constraint(equalTo: titleLabel.superview!.rightAnchor).isActive = true
    titleLabel.centerYAnchor.constraint(equalTo: titleLabel.superview!.centerYAnchor).isActive = true
  }

  func configure(_ item: inout Item) {
    titleLabel.text = item.title
  }
}

class CustomListCell: View, ItemConfigurable {

  var preferredViewSize: CGSize = CGSize(width: 0, height: 44)

  func configure(_ item: inout Item) {
    textLabel?.text = item.text
  }
}

class CustomListHeaderView: View, Componentable {
  var preferredHeaderHeight: CGFloat = 88

  func configure(_ component: Component) {
    textLabel?.text = component.title
  }
}

class CustomGridCell: View, ItemConfigurable {

  var preferredViewSize: CGSize = CGSize(width: 0, height: 44)

  func configure(_ item: inout Item) {}
}

class CustomGridHeaderView: View, Componentable {

  var preferredHeaderHeight: CGFloat = 88

  lazy var textLabel = UILabel()

  func configure(_ component: Component) {
    textLabel.text = component.title
  }
}
