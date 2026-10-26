enum HieloActivationResult: Equatable, Sendable {
  case started
  case sourceUnavailable
  case blockedByActivePresentation(HieloSession.Status)

  var succeeded: Bool {
    self == .started
  }
}
