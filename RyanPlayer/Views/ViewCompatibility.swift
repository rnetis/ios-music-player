import SwiftUI

/// iOS 16+ APIs used by the UI, guarded for the iOS 15 deployment target.
extension View {
    /// `.toolbarBackground(_:for:)` is iOS 16+; no-op on iOS 15.
    @ViewBuilder
    func toolbarBackgroundCompat(visible: Bool = false) -> some View {
        if #available(iOS 16.0, *) {
            if visible {
                self.toolbarBackground(.visible, for: .navigationBar)
                    .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            } else {
                self.toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            }
        } else {
            self
        }
    }

    /// `.scrollContentBackground(_:)` is iOS 16+; no-op on iOS 15.
    @ViewBuilder
    func hiddenScrollContentBackground() -> some View {
        if #available(iOS 16.0, *) {
            self.scrollContentBackground(.hidden)
        } else {
            self
        }
    }
}
