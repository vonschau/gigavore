import SwiftUI

@main
struct SpaceLensApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var model = AppModel()

    var body: some Scene {
        WindowGroup("Space Lens") {
            ContentView()
                .environment(model)
                .frame(minWidth: 900, minHeight: 560)
        }
    }
}

/// Makes the app behave like a regular GUI app (Dock icon, window in front)
/// even when launched via `swift run`.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

struct ContentView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        Group {
            switch model.phase {
            case .welcome:
                WelcomeView()
            case .scanning:
                ScanningView()
            case .results:
                if let current = model.current {
                    ResultsView(current: current)
                } else {
                    WelcomeView()
                }
            }
        }
        .alert("Error", isPresented: Binding(
            get: { model.errorMessage != nil },
            set: { if !$0 { model.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(model.errorMessage ?? "")
        }
    }
}
