import SwiftUI

/// Main results screen: breadcrumb, treemap, and a sidebar item list.
struct ResultsView: View {
    @Environment(AppModel.self) private var model
    let current: FileNode

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            HSplitView {
                TreemapView(node: current)
                    .frame(minWidth: 420, maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(nsColor: .underPageBackgroundColor))
                ChildrenListView(node: current)
                    .frame(minWidth: 240, idealWidth: 290, maxWidth: 400)
            }
            Divider()
            footer
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button {
                model.goUp()
            } label: {
                Image(systemName: "chevron.up")
            }
            .disabled(model.path.count <= 1)
            .help("Go up one level")

            BreadcrumbView()

            Spacer()

            Text("\(current.fileCount.formatted()) files · \(current.formattedSize)")
                .font(.callout)
                .foregroundStyle(.secondary)

            Button("Rescan") { model.rescan() }
            Button("New Scan") { model.newScan() }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var footer: some View {
        HStack {
            if let hovered = model.hovered {
                Image(systemName: hovered.isDirectory ? "folder.fill" : "doc.fill")
                    .foregroundStyle(.secondary)
                Text(hovered.url.path)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
                if hovered.isDirectory {
                    Text("\(hovered.fileCount.formatted()) files")
                        .foregroundStyle(.secondary)
                }
                Text(hovered.formattedSize)
                    .fontWeight(.semibold)
                Text(percentString(of: hovered))
                    .foregroundStyle(.secondary)
            } else {
                Text("Click a folder to drill down · right-click for actions")
                    .foregroundStyle(.tertiary)
                Spacer()
            }
        }
        .font(.callout)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .frame(height: 30)
    }

    private func percentString(of node: FileNode) -> String {
        let fraction = current.fraction(of: node)
        return fraction.formatted(.percent.precision(.fractionLength(1)))
    }
}

/// Breadcrumb navigation — clicking a component jumps back to that level.
struct BreadcrumbView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(Array(model.path.enumerated()), id: \.element.id) { index, node in
                    if index > 0 {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9))
                            .foregroundStyle(.tertiary)
                    }
                    Button {
                        model.jump(toPathIndex: index)
                    } label: {
                        Text(node.name)
                            .fontWeight(index == model.path.count - 1 ? .semibold : .regular)
                            .foregroundStyle(index == model.path.count - 1 ? .primary : .secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: 500)
    }
}

/// List of the current directory's items sorted by size.
struct ChildrenListView: View {
    @Environment(AppModel.self) private var model
    let node: FileNode

    private static let maxRows = 300

    var body: some View {
        List {
            ForEach(node.children.prefix(Self.maxRows)) { child in
                ChildRow(parent: node, child: child)
            }
            if node.children.count > Self.maxRows {
                Text("… and \((node.children.count - Self.maxRows).formatted()) more items")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .listStyle(.inset)
    }
}

private struct ChildRow: View {
    @Environment(AppModel.self) private var model
    let parent: FileNode
    let child: FileNode

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: child.isDirectory ? "folder.fill" : "doc")
                .foregroundStyle(child.isDirectory ? Color.accentColor : Color.secondary)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 2) {
                Text(child.name)
                    .lineLimit(1)
                    .truncationMode(.middle)
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.secondary.opacity(0.15))
                        Capsule()
                            .fill(Color.accentColor.opacity(0.7))
                            .frame(width: max(2, proxy.size.width * parent.fraction(of: child)))
                    }
                }
                .frame(height: 4)
            }

            Spacer(minLength: 8)

            Text(child.formattedSize)
                .font(.callout.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .onTapGesture {
            if child.isDirectory {
                model.drillDown(into: child)
            }
        }
        .onHover { inside in
            if inside {
                model.hovered = child
            } else if model.hovered === child {
                model.hovered = nil
            }
        }
        .contextMenu {
            Button("Reveal in Finder") { model.revealInFinder(child) }
            Divider()
            Button("Move to Trash", role: .destructive) { model.moveToTrash(child) }
        }
    }
}
