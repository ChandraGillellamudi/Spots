import Foundation
import CoreGraphics

public class SizeCache {

  enum SizeKey {
    case width, height
  }

  public var sizes = [CGSize]()

  func add(_ size: CGSize, for index: Int) {
    guard index >= 0 else {
      assertionFailure("Index has to be larger than 0")
      return
    }

    if index > sizes.count - 1 {
      sizes.append(size)
    } else {
      sizes[index] = size
    }
  }

  func updateOrCreate(_ key: SizeKey, value: CGFloat, for index: Int) {
    guard index >= 0 else {
      assertionFailure("Index has to be larger than 0")
      return
    }

    if index > sizes.count - 1 {
      let size: CGSize
      switch key {
      case .width:
        size = .init(width: value, height: 0)
      case .height:
        size = .init(width: 0, height: value)
      }

      sizes.append(size)
    } else {
      switch key {
      case .width:
        sizes[index].width = value
      case .height:
        sizes[index].height = value
      }
    }
  }

  func size(at indexPath: IndexPath) -> CGSize {
    return size(at: indexPath.item)
  }

  func size(at index: Int) -> CGSize {
    guard index >= 0 else {
      assertionFailure("Index has to be larger than 0")
      return .zero
    }

    if index < sizes.count {
      return sizes[index]
    } else {
      return .zero
    }
  }

  func totalHeight() -> CGFloat {
    var height: CGFloat = 0.0
    for size in sizes {
      height += size.height
    }
    return height
  }

  private func safelyResolve(index: Int, closure: (CGSize, Bool) -> Void) {
    guard index >= 0 else {
      assertionFailure("Index has to be larger than 0")
      return
    }

    if index < sizes.count {
      closure(sizes[index], true)
    }
  }
}
