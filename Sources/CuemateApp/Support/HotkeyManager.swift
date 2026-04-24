import Carbon
import Foundation

@MainActor
final class HotkeyManager: ObservableObject {
    private var hotKeys: [EventHotKeyRef?] = []
    private var handler: EventHandlerRef?
    private weak var model: AppModel?

    func bind(model: AppModel) async {
        self.model = model

        guard handler == nil else { return }

        let eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard let userData else { return noErr }

                let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
                var hotKeyID = EventHotKeyID()
                let result = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )

                guard result == noErr else { return result }
                manager.dispatch(id: hotKeyID.id)
                return noErr
            },
            1,
            [eventSpec],
            Unmanaged.passUnretained(self).toOpaque(),
            &handler
        )

        guard status == noErr else {
            model.appendLog("Global hotkey registration handler failed with status \(status)")
            return
        }

        registerAll()
        model.appendLog("Registered global hotkeys for live controls")
    }

    private func registerAll() {
        hotKeys.removeAll()

        for binding in HotkeyBinding.defaultBindings {
            var hotKeyRef: EventHotKeyRef?
            let hotKeyID = EventHotKeyID(signature: binding.signature, id: UInt32(binding.actionIndex))
            let status = RegisterEventHotKey(
                UInt32(binding.keyCode),
                binding.modifiers,
                hotKeyID,
                GetApplicationEventTarget(),
                0,
                &hotKeyRef
            )

            if status == noErr {
                hotKeys.append(hotKeyRef)
            } else {
                model?.appendLog("Failed to register hotkey \(binding.action.title) with status \(status)")
            }
        }
    }

    private func dispatch(id: UInt32) {
        guard let action = HotkeyBinding.action(for: Int(id)) else { return }
        model?.handleHotkeyAction(action)
    }
}

private struct HotkeyBinding {
    let action: ConversationAction
    let keyCode: Int
    let modifiers: UInt32
    let signature: OSType = OSType(0x4355454D) // "CUEM"

    var actionIndex: Int {
        ConversationAction.allCases.firstIndex(of: action) ?? 0
    }

    static let defaultBindings: [HotkeyBinding] = [
        HotkeyBinding(action: .toggleOverlay, keyCode: kVK_ANSI_H, modifiers: UInt32(cmdKey | shiftKey)),
        HotkeyBinding(action: .pauseResume, keyCode: kVK_ANSI_P, modifiers: UInt32(cmdKey)),
        HotkeyBinding(action: .nextSuggestion, keyCode: kVK_RightArrow, modifiers: UInt32(cmdKey)),
        HotkeyBinding(action: .shorten, keyCode: kVK_ANSI_S, modifiers: UInt32(cmdKey)),
        HotkeyBinding(action: .expand, keyCode: kVK_ANSI_L, modifiers: UInt32(cmdKey)),
        HotkeyBinding(action: .moreConfident, keyCode: kVK_ANSI_C, modifiers: UInt32(cmdKey)),
        HotkeyBinding(action: .regenerate, keyCode: kVK_ANSI_R, modifiers: UInt32(cmdKey))
    ]

    static func action(for index: Int) -> ConversationAction? {
        guard defaultBindings.indices.contains(index) else { return nil }
        return defaultBindings[index].action
    }
}
