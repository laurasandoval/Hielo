import SwiftUI

extension HieloSession {
  // MARK: - Restoration internals

  func beginRestoring(
    pin: HieloPin,
    focusFirstResponder: @escaping @MainActor () -> Void
  ) {
    keyboardTransitionTask?.cancel()
    let presentation = HieloRestorationPresentation(
      pin: pin,
      runtime: runtime
    )
    setStorage(.restoring(pin, presentation))
    installKeyboardShowObservers(for: presentation)
    focusFirstResponder()

    startTransitionTimeout(configuration.restorationTimeout) {
      [weak self, weak presentation] in
      guard let self, let presentation else { return }
      finishKeyboardRestoration(presentation)
    }
  }

  func beginRepinning(
    pin: HieloPin,
    presentation: HieloRestorationPresentation,
    resignFirstResponder: @escaping @MainActor () -> Void
  ) {
    transitionTimeoutTask?.cancel()
    removeKeyboardShowObservers()
    setStorage(.repinning(pin, presentation, pendingFocus: nil))
    installKeyboardDidHideObserver(for: presentation)
    resignWithoutAnimationAcrossNextTurn(resignFirstResponder)

    startTransitionTimeout(configuration.repinningTimeout) {
      [weak self, weak presentation] in
      guard let self, let presentation else { return }
      finishRepinning(presentation)
    }
  }

  private func finishKeyboardRestoration(
    _ presentation: HieloRestorationPresentation
  ) {
    guard case .restoring(let pin, let currentPresentation) = storage,
      currentPresentation === presentation
    else { return }

    transitionTimeoutTask?.cancel()
    transitionTimeoutTask = nil
    removeKeyboardShowObservers()
    presentation.tearDown()
    pin.snapshotView.removeFromSuperview()
    setStorage(.idle)
  }

  private func finishRepinning(
    _ presentation: HieloRestorationPresentation
  ) {
    guard case .repinning(let pin, let currentPresentation, let pendingFocus) = storage,
      currentPresentation === presentation
    else { return }

    transitionTimeoutTask?.cancel()
    transitionTimeoutTask = nil
    removeKeyboardDidHideObserver()
    presentation.tearDown()
    setStorage(.pinned(pin))

    if let pendingFocus {
      beginRestoring(pin: pin, focusFirstResponder: pendingFocus)
    }
  }

  // MARK: - Keyboard lifecycle

  private func installKeyboardShowObservers(
    for presentation: HieloRestorationPresentation
  ) {
    removeKeyboardShowObservers()
    keyboardWillShowObserver = notificationCenter.addObserver(
      forName: UIResponder.keyboardWillShowNotification,
      object: nil,
      queue: .main
    ) { [weak self, weak presentation] _ in
      Task { @MainActor in
        guard let self, let presentation else { return }
        guard case .restoring(_, let currentPresentation) = self.storage,
          currentPresentation === presentation
        else { return }
        presentation.hideKeyboardWindows()
      }
    }
    keyboardDidShowObserver = notificationCenter.addObserver(
      forName: UIResponder.keyboardDidShowNotification,
      object: nil,
      queue: .main
    ) { [weak self, weak presentation] _ in
      Task { @MainActor in
        guard let self, let presentation else { return }
        self.finishKeyboardRestoration(presentation)
      }
    }
  }

  private func installKeyboardDidHideObserver(
    for presentation: HieloRestorationPresentation
  ) {
    removeKeyboardDidHideObserver()
    keyboardDidHideObserver = notificationCenter.addObserver(
      forName: UIResponder.keyboardDidHideNotification,
      object: nil,
      queue: .main
    ) { [weak self, weak presentation] _ in
      Task { @MainActor in
        guard let self, let presentation else { return }
        self.finishRepinning(presentation)
      }
    }
  }

  private func startTransitionTimeout(
    _ duration: Duration,
    action: @escaping @MainActor () -> Void
  ) {
    transitionTimeoutTask?.cancel()
    transitionTimeoutTask = Task { @MainActor in
      try? await Task.sleep(for: duration)
      guard !Task.isCancelled else { return }
      action()
    }
  }

  func resignWithoutAnimationAcrossNextTurn(
    _ resignFirstResponder: @escaping @MainActor () -> Void
  ) {
    keyboardTransitionTask?.cancel()
    let suppressionID = UUID()
    if animationSuppressionID == nil {
      animationsWereEnabledBeforeSuppression = UIView.areAnimationsEnabled
    }
    animationSuppressionID = suppressionID
    UIView.setAnimationsEnabled(false)
    resignFirstResponder()

    keyboardTransitionTask = Task { @MainActor [weak self] in
      await Task.yield()
      self?.finishAnimationSuppression(suppressionID)
    }
  }

  private func finishAnimationSuppression(_ suppressionID: UUID? = nil) {
    if let suppressionID, animationSuppressionID != suppressionID {
      return
    }
    guard let animationsWereEnabledBeforeSuppression else { return }
    UIView.setAnimationsEnabled(animationsWereEnabledBeforeSuppression)
    animationSuppressionID = nil
    self.animationsWereEnabledBeforeSuppression = nil
  }

  // MARK: - Cleanup

  func cancelTasksAndObservers() {
    overlayDismissalTask?.cancel()
    overlayDismissalTask = nil
    keyboardTransitionTask?.cancel()
    keyboardTransitionTask = nil
    finishAnimationSuppression()
    transitionTimeoutTask?.cancel()
    transitionTimeoutTask = nil
    removeKeyboardShowObservers()
    removeKeyboardDidHideObserver()
  }

  private func removeKeyboardShowObservers() {
    if let keyboardWillShowObserver {
      notificationCenter.removeObserver(keyboardWillShowObserver)
      self.keyboardWillShowObserver = nil
    }
    if let keyboardDidShowObserver {
      notificationCenter.removeObserver(keyboardDidShowObserver)
      self.keyboardDidShowObserver = nil
    }
  }

  private func removeKeyboardDidHideObserver() {
    guard let keyboardDidHideObserver else { return }
    notificationCenter.removeObserver(keyboardDidHideObserver)
    self.keyboardDidHideObserver = nil
  }
}
