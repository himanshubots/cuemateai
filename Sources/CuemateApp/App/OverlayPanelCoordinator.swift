import AppKit
import SwiftUI

enum OverlayAnchor: String, CaseIterable, Codable, Sendable, Identifiable {
    case topLeft
    case topCenter
    case topRight

    var id: String { rawValue }

    var title: String {
        switch self {
        case .topLeft: "Top Left"
        case .topCenter: "Top Center"
        case .topRight: "Top Right"
        }
    }
}

@MainActor
final class OverlayPanelCoordinator {
    private var panel: OverlayPanel?

    func present(model: AppModel) {
        if panel == nil {
            let contentView = OverlayPanelView(model: model)
            let hosting = NSHostingView(rootView: contentView)

            let panel = OverlayPanel(
                contentRect: NSRect(x: 0, y: 0, width: 420, height: 220),
                styleMask: [.nonactivatingPanel, .borderless],
                backing: .buffered,
                defer: false
            )
            panel.isFloatingPanel = true
            panel.level = .statusBar
            panel.backgroundColor = .clear
            panel.isOpaque = false
            panel.hasShadow = true
            // Best effort only: Apple no longer guarantees this excludes a window
            // from modern screen recording or sharing pipelines.
            panel.sharingType = .none
            panel.isMovableByWindowBackground = true
            panel.hidesOnDeactivate = false
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel.contentView = hosting
            placeNearCamera(
                panel,
                anchor: model.overlayAnchor,
                horizontalInset: model.overlayHorizontalInset,
                verticalInset: model.overlayVerticalInset
            )

            self.panel = panel
        }

        panel?.orderFrontRegardless()
    }

    func hide() {
        panel?.orderOut(nil)
    }

    func updateClickThrough(_ enabled: Bool) {
        panel?.ignoresMouseEvents = enabled
    }

    func pinNearCamera(anchor: OverlayAnchor = .topCenter, horizontalInset: Double = 0, verticalInset: Double = 0) {
        guard let panel else { return }
        placeNearCamera(panel, anchor: anchor, horizontalInset: horizontalInset, verticalInset: verticalInset)
        panel.orderFrontRegardless()
    }

    func syncPlacementIfVisible(anchor: OverlayAnchor, horizontalInset: Double, verticalInset: Double) {
        guard let panel, panel.isVisible else { return }
        placeNearCamera(panel, anchor: anchor, horizontalInset: horizontalInset, verticalInset: verticalInset)
    }

    private func placeNearCamera(
        _ panel: NSPanel,
        anchor: OverlayAnchor = .topCenter,
        horizontalInset: Double = 0,
        verticalInset: Double = 0
    ) {
        let targetScreen = NSScreen.screens.first(where: { $0.frame.origin == .zero }) ?? NSScreen.main
        guard let screen = targetScreen else {
            panel.center()
            return
        }

        let visibleFrame = screen.visibleFrame
        let x: CGFloat
        switch anchor {
        case .topLeft:
            x = visibleFrame.minX + 28 + CGFloat(horizontalInset)
        case .topCenter:
            x = visibleFrame.midX - (panel.frame.width / 2) + CGFloat(horizontalInset)
        case .topRight:
            x = visibleFrame.maxX - panel.frame.width - 28 + CGFloat(horizontalInset)
        }

        let y = visibleFrame.maxY - panel.frame.height - 36 - CGFloat(verticalInset)
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
}

final class OverlayPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
