import SwiftUI

/// Landing screen — pick a location to scan.
struct WelcomeView: View {
    @Environment(AppModel.self) private var model

    private var home: URL { FileManager.default.homeDirectoryForCurrentUser }

    var body: some View {
        VStack(spacing: 28) {
            VStack(spacing: 8) {
                Image(systemName: "circle.hexagongrid.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(.linearGradient(
                        colors: [.orange, .pink],
                        startPoint: .topLeading, endPoint: .bottomTrailing))
                Text("Space Lens")
                    .font(.largeTitle.bold())
                Text("Find out what is eating your disk space")
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 10) {
                quickButton("Home Folder", icon: "house.fill", url: home)
                quickButton("Downloads", icon: "arrow.down.circle.fill",
                            url: home.appendingPathComponent("Downloads"))
                quickButton("Applications", icon: "app.fill", url: URL(fileURLWithPath: "/Applications"))
                quickButton("Entire Disk", icon: "internaldrive.fill", url: URL(fileURLWithPath: "/"))

                Button {
                    pickFolder()
                } label: {
                    Label("Choose Folder…", systemImage: "folder.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .controlSize(.large)
            }
            .frame(width: 320)

            Text("To scan the entire disk, grant the app Full Disk Access\nin System Settings → Privacy & Security.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func quickButton(_ title: String, icon: String, url: URL) -> some View {
        Button {
            model.startScan(url: url)
        } label: {
            HStack {
                Image(systemName: icon)
                    .frame(width: 20)
                Text(title)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity)
        }
        .controlSize(.large)
    }

    private func pickFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Scan"
        if panel.runModal() == .OK, let url = panel.url {
            model.startScan(url: url)
        }
    }
}

/// Scan progress screen.
struct ScanningView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .controlSize(.large)

            Text("Scanning \(model.scannedURL?.path ?? "")…")
                .font(.title3.weight(.semibold))

            VStack(spacing: 6) {
                Text("\(model.scannedFiles.formatted()) files · \(ByteCountFormatter.string(fromByteCount: model.scannedBytes, countStyle: .file))")
                    .font(.body.monospacedDigit())
                Text(model.scanningPath)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: 420)
            }

            Button("Cancel") { model.cancelScan() }
                .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
