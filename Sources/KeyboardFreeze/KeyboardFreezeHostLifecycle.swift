/// Controls who tears down a keyboard freeze session when its host disappears.
public enum KeyboardFreezeHostLifecycle: Equatable, Sendable {
  /// The safe default for a screen-owned session.
  case cancelOnDisappear

  /// Use when a session intentionally outlives a particular host view.
  case manual
}
