import SwiftUI

/// Visualizes the contents of the current directory as a squarified treemap.
struct TreemapView: View {
    @Environment(AppModel.self) private var model
    let node: FileNode

    private static let maxTiles = 150

    private struct Tile: Identifiable {
        let id: UUID
        let node: FileNode
        let rect: CGRect
        let colorIndex: Int
    }

    var body: some View {
        GeometryReader { proxy in
            let tiles = makeTiles(in: CGRect(origin: .zero, size: proxy.size))
            ZStack(alignment: .topLeading) {
                if tiles.isEmpty {
                    emptyState
                        .frame(width: proxy.size.width, height: proxy.size.height)
                }
                ForEach(tiles) { tile in
                    TreemapTile(
                        node: tile.node,
                        colorIndex: tile.colorIndex,
                        isHovered: model.hovered === tile.node
                    )
                    .frame(width: tile.rect.width, height: tile.rect.height)
                    .offset(x: tile.rect.minX, y: tile.rect.minY)
                }
            }
            .animation(.easeOut(duration: 0.2), value: node.id)
        }
        .padding(6)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: node.isAccessDenied ? "lock.fill" : "folder")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
            Text(node.isAccessDenied
                 ? "No permission to read this folder"
                 : "Empty folder, or items too small to display")
                .foregroundStyle(.secondary)
        }
    }

    private func makeTiles(in rect: CGRect) -> [Tile] {
        let visible = node.children.filter { $0.size > 0 }
        guard !visible.isEmpty, rect.width > 4, rect.height > 4 else { return [] }

        let shown = Array(visible.prefix(Self.maxTiles))
        let values = shown.map { Double($0.size) }
        let rects = Squarify.layout(values: values, in: rect.insetBy(dx: 1, dy: 1))

        var tiles: [Tile] = []
        for (index, child) in shown.enumerated() {
            let r = rects[index].insetBy(dx: 1.5, dy: 1.5)
            guard r.width > 2, r.height > 2 else { continue }
            tiles.append(Tile(id: child.id, node: child, rect: r, colorIndex: index))
        }
        return tiles
    }
}

private struct TreemapTile: View {
    @Environment(AppModel.self) private var model
    let node: FileNode
    let colorIndex: Int
    let isHovered: Bool

    var body: some View {
        let color = TreemapPalette.color(for: node, index: colorIndex)
        RoundedRectangle(cornerRadius: 4)
            .fill(color.opacity(isHovered ? 1.0 : 0.85))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(isHovered ? Color.white.opacity(0.9) : Color.black.opacity(0.15),
                                  lineWidth: isHovered ? 2 : 1)
            )
            .overlay(alignment: .topLeading) { label }
            .contentShape(Rectangle())
            .onHover { inside in
                if inside {
                    model.hovered = node
                } else if model.hovered === node {
                    model.hovered = nil
                }
            }
            .onTapGesture {
                model.drillDown(into: node)
            }
            .contextMenu {
                Button("Reveal in Finder") { model.revealInFinder(node) }
                if node.isDirectory && !node.children.isEmpty {
                    Button("Open in Treemap") { model.drillDown(into: node) }
                }
                Divider()
                Button("Move to Trash", role: .destructive) { model.moveToTrash(node) }
            }
            .help("\(node.name) — \(node.formattedSize)")
    }

    @ViewBuilder
    private var label: some View {
        GeometryReader { proxy in
            if proxy.size.width > 56 && proxy.size.height > 30 {
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 3) {
                        if node.isDirectory {
                            Image(systemName: "folder.fill").font(.system(size: 9))
                        }
                        Text(node.name)
                            .font(.system(size: 11, weight: .semibold))
                            .lineLimit(1)
                    }
                    if proxy.size.height > 44 {
                        Text(node.formattedSize)
                            .font(.system(size: 10))
                            .opacity(0.85)
                    }
                }
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.4), radius: 1, y: 0.5)
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
            }
        }
    }
}

enum TreemapPalette {
    private static let colors: [Color] = [
        Color(red: 0.95, green: 0.61, blue: 0.15),  // orange
        Color(red: 0.25, green: 0.56, blue: 0.92),  // blue
        Color(red: 0.36, green: 0.72, blue: 0.36),  // green
        Color(red: 0.85, green: 0.35, blue: 0.37),  // red
        Color(red: 0.60, green: 0.42, blue: 0.86),  // purple
        Color(red: 0.22, green: 0.68, blue: 0.72),  // teal
        Color(red: 0.91, green: 0.47, blue: 0.65),  // pink
        Color(red: 0.71, green: 0.63, blue: 0.28),  // olive
        Color(red: 0.47, green: 0.55, blue: 0.65),  // slate
        Color(red: 0.80, green: 0.52, blue: 0.25),  // brown
    ]

    static func color(for node: FileNode, index: Int) -> Color {
        let base = colors[index % colors.count]
        // Dim files slightly so clickable folders stand out.
        return node.isDirectory ? base : base.opacity(0.75)
    }
}
