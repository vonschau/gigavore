import Foundation

/// A node in the file system tree. The tree is built on a background thread
/// during scanning; once complete it is only touched from the main thread
/// (navigation, deletion).
final class FileNode: Identifiable, @unchecked Sendable {
    let id = UUID()
    let name: String
    let url: URL
    let isDirectory: Bool
    /// Allocated size in bytes (for directories, the sum of contents).
    var size: Int64
    /// Children sorted by size, descending. Empty for files.
    var children: [FileNode]
    /// Number of files in the subtree (1 for a file).
    let fileCount: Int
    /// Directory that could not be read (missing permissions).
    let isAccessDenied: Bool

    init(name: String, url: URL, isDirectory: Bool, size: Int64,
         children: [FileNode] = [], fileCount: Int, isAccessDenied: Bool = false) {
        self.name = name
        self.url = url
        self.isDirectory = isDirectory
        self.size = size
        self.children = children
        self.fileCount = fileCount
        self.isAccessDenied = isAccessDenied
    }

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    /// Fraction of this node's size taken by the given child (0...1).
    func fraction(of child: FileNode) -> Double {
        guard size > 0 else { return 0 }
        return Double(child.size) / Double(size)
    }
}
