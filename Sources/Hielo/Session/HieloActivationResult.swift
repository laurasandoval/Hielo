/// The result of an attempt to start a keyboard presentation.
public enum HieloActivationResult: Equatable, Sendable {
  /// The requested presentation started.
  case started
  /// The requested pinning operation is already active.
  case alreadyActive
  /// A live keyboard snapshot could not be captured.
  case keyboardUnavailable
  /// The source could not be resolved in the required window or screen.
  case sourceUnavailable
  /// Another presentation prevents the operation. The associated value is its status.
  case blockedByActivePresentation(HieloSession.Status)

  /// A Boolean value indicating whether the operation started or was already active.
  public var succeeded: Bool {
    switch self {
    case .started, .alreadyActive:
      true
    case .keyboardUnavailable, .sourceUnavailable, .blockedByActivePresentation:
      false
    }
  }
}
