public enum ComponentState: Int, Equatable {
  case initializing, setup, ready, updating, deinitializing

  public static func == (lhs: ComponentState, rhs: ComponentState) -> Bool {
    return lhs.rawValue == rhs.rawValue
  }
}
