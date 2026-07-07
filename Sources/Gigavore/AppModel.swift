import SwiftUI
import Observation

@MainActor
@Observable
final class AppModel {
    enum Phase {
        case welcome
        case scanning
        case results
    }

    var phase: Phase = .welcome

    // Scan result and navigation
    var root: FileNode?
    /// Path from the root to the currently displayed directory (breadcrumb).
    var path: [FileNode] = []
    var current: FileNode? { path.last }
    var hovered: FileNode?

    // Scan progress
    var scannedFiles = 0
    var scannedBytes: Int64 = 0
    var scanningPath = ""
    var scannedURL: URL?

    var errorMessage: String?

    private let progress = ScanProgress()
    private var scanTask: Task<Void, Never>?

    func startScan(url: URL) {
        scannedURL = url
        scannedFiles = 0
        scannedBytes = 0
        scanningPath = url.path
        hovered = nil
        progress.reset()
        phase = .scanning

        let progress = self.progress
        scanTask = Task {
            // Poll progress periodically while the scan is running.
            let poller = Task { [weak self] in
                while !Task.isCancelled {
                    try? await Task.sleep(for: .milliseconds(150))
                    guard let self else { return }
                    let snapshot = progress.snapshot()
                    self.scannedFiles = snapshot.files
                    self.scannedBytes = snapshot.bytes
                    self.scanningPath = snapshot.currentPath
                }
            }

            let node = await Task.detached(priority: .userInitiated) {
                DiskScanner.scan(url: url, progress: progress)
            }.value

            poller.cancel()

            if progress.isCancelled {
                phase = .welcome
            } else {
                root = node
                path = [node]
                phase = .results
            }
        }
    }

    func cancelScan() {
        progress.cancel()
    }

    func newScan() {
        root = nil
        path = []
        hovered = nil
        phase = .welcome
    }

    func rescan() {
        guard let url = scannedURL else { return }
        startScan(url: url)
    }

    // MARK: - Navigation

    func drillDown(into node: FileNode) {
        guard node.isDirectory, !node.children.isEmpty else { return }
        hovered = nil
        path.append(node)
    }

    func jump(toPathIndex index: Int) {
        guard index >= 0, index < path.count else { return }
        hovered = nil
        path = Array(path.prefix(index + 1))
    }

    func goUp() {
        guard path.count > 1 else { return }
        hovered = nil
        path.removeLast()
    }

    // MARK: - File actions

    func revealInFinder(_ node: FileNode) {
        NSWorkspace.shared.activateFileViewerSelecting([node.url])
    }

    /// Moves the item to the Trash and subtracts its size from all ancestors.
    func moveToTrash(_ node: FileNode) {
        do {
            try FileManager.default.trashItem(at: node.url, resultingItemURL: nil)
        } catch {
            errorMessage = "Could not move “\(node.name)” to Trash: \(error.localizedDescription)"
            return
        }
        if hovered === node { hovered = nil }
        current?.children.removeAll { $0 === node }
        for ancestor in path {
            ancestor.size -= node.size
        }
    }
}
