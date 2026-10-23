/// The cleanup behavior when a view hosting a keyboard-freeze session disappears.
public enum KeyboardFreezeHostLifecycle: Equatable, Sendable {
  /// Cancels the session when the host disappears.
  case cancelOnDisappear

  /// Leaves cleanup to the caller when the host disappears.
  ///
  /// Call ``KeyboardFreeze/cancel()`` when the session is no longer needed.
  case manual
}
