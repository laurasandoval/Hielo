/// Describes whether a keyboard presentation started and, when it did not, why.
public enum KeyboardFreezeActivationResult: Equatable, Sendable {
  case started
  case alreadyActive
  case keyboardUnavailable
  case sourceUnavailable
  case blockedByActivePresentation(KeyboardFreeze.Status)

  public var succeeded: Bool {
    switch self {
    case .started, .alreadyActive:
      true
    case .keyboardUnavailable, .sourceUnavailable, .blockedByActivePresentation:
      false
    }
  }
}
