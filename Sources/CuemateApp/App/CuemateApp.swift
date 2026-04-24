import SwiftUI

@main
struct CuemateApp: App {
    @StateObject private var model = AppModel()
    @StateObject private var hotkeyManager = HotkeyManager()

    var body: some Scene {
        WindowGroup("cuemate") {
            RootView(model: model)
                .frame(minWidth: 980, minHeight: 680)
                .task {
                    await model.refreshDependencyStatuses()
                }
                .task {
                    await hotkeyManager.bind(model: model)
                }
        }

        MenuBarExtra("cuemate", systemImage: "waveform.and.mic") {
            MenuBarContentView(model: model)
                .frame(width: 320)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(model: model)
                .frame(width: 520, height: 420)
        }
    }
}
