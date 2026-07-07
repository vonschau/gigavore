import Foundation
import Synchronization

/// Shared scan progress state — the scanner writes to it from a background
/// thread, the UI polls it periodically.
final class ScanProgress: Sendable {
    private struct State {
        var files = 0
        var bytes: Int64 = 0
        var currentPath = ""
        var cancelled = false
    }

    private let state = Mutex(State())

    func reset() {
        state.withLock { $0 = State() }
    }

    func cancel() {
        state.withLock { $0.cancelled = true }
    }

    var isCancelled: Bool {
        state.withLock { $0.cancelled }
    }

    func addFile(bytes: Int64) {
        state.withLock {
            $0.files += 1
            $0.bytes += bytes
        }
    }

    func enteredDirectory(_ path: String) {
        state.withLock { $0.currentPath = path }
    }

    func snapshot() -> (files: Int, bytes: Int64, currentPath: String) {
        state.withLock { ($0.files, $0.bytes, $0.currentPath) }
    }
}

enum DiskScanner {
    private static let resourceKeys: Set<URLResourceKey> = [
        .isDirectoryKey,
        .isSymbolicLinkKey,
        .isVolumeKey,
        .totalFileAllocatedSizeKey,
        .fileAllocatedSizeKey,
    ]

    /// Scans the tree under `url`. Returns the root node; on cancellation it
    /// returns a partial result. Symlinks and mounted volumes inside the tree
    /// are skipped to avoid cycles and scanning external disks.
    static func scan(url: URL, progress: ScanProgress) -> FileNode {
        let values = try? url.resourceValues(forKeys: resourceKeys)
        if values?.isDirectory == true {
            return scanDirectory(url, progress: progress, isRoot: true)
        }
        let size = Int64(values?.totalFileAllocatedSize ?? values?.fileAllocatedSize ?? 0)
        return FileNode(name: url.lastPathComponent, url: url,
                        isDirectory: false, size: size, fileCount: 1)
    }

    private static func scanDirectory(_ url: URL, progress: ScanProgress, isRoot: Bool = false) -> FileNode {
        progress.enteredDirectory(url.path)

        let contents: [URL]
        do {
            contents = try FileManager.default.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: Array(resourceKeys),
                options: []
            )
        } catch {
            return FileNode(name: url.lastPathComponent, url: url, isDirectory: true,
                            size: 0, fileCount: 0, isAccessDenied: true)
        }

        var children: [FileNode] = []
        children.reserveCapacity(contents.count)
        var totalSize: Int64 = 0
        var totalFiles = 0

        for item in contents {
            if progress.isCancelled { break }
            guard let values = try? item.resourceValues(forKeys: resourceKeys) else { continue }
            if values.isSymbolicLink == true { continue }
            if values.isVolume == true { continue }

            let child: FileNode
            if values.isDirectory == true {
                child = scanDirectory(item, progress: progress)
            } else {
                let size = Int64(values.totalFileAllocatedSize ?? values.fileAllocatedSize ?? 0)
                child = FileNode(name: item.lastPathComponent, url: item,
                                 isDirectory: false, size: size, fileCount: 1)
                progress.addFile(bytes: size)
            }
            totalSize += child.size
            totalFiles += child.fileCount
            children.append(child)
        }

        children.sort { $0.size > $1.size }
        return FileNode(name: isRoot ? url.path : url.lastPathComponent,
                        url: url, isDirectory: true, size: totalSize,
                        children: children, fileCount: totalFiles)
    }
}
