/// A container that presents rows of data arranged in columns.
public struct Table<RowValue, RowContent: TableRowContent<RowValue>>: TypeSafeView, View {
    typealias Children = TableViewChildren<RowContent.RowContent>

    public var state = EmptyState()
    public var body = EmptyView()

    public var flexibility: Int {
        500
    }

    /// The row data to display.
    private var rows: [RowValue]
    /// The columns to display (which each compute their cell values when given
    /// ``Table/Row`` instances).
    private var columns: RowContent

    /// Creates a table that computes its cell values based on a collection of rows.
    public init(_ rows: [RowValue], @TableRowBuilder<RowValue> _ columns: () -> RowContent) {
        self.rows = rows
        self.columns = columns()
    }

    func children<Backend: AppBackend>(
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: Environment
    ) -> Children {
        // TODO: Table snapshotting
        TableViewChildren()
    }

    func asWidget<Backend: AppBackend>(
        _ children: Children,
        backend: Backend
    ) -> Backend.Widget {
        return backend.createTable()
    }

    func update<Backend: AppBackend>(
        _ widget: Backend.Widget,
        children: Children,
        proposedSize: SIMD2<Int>,
        environment: Environment,
        backend: Backend
    ) -> ViewUpdateResult {
        let rowContent = rows.map(columns.content(for:)).map(RowView.init(_:))

        for (node, content) in zip(children.rowNodes, rowContent) {
            // Updating a RowView simply updates the view stored within its node, so the proposedSize
            // is irrelevant. We can just set it to `.zero`.
            _ = node.update(with: content, proposedSize: .zero, environment: environment)
        }

        let columnLabels = columns.labels
        let columnCount = columnLabels.count
        let remainder = rowContent.count - children.rowNodes.count
        if remainder < 0 {
            children.rowNodes.removeLast(-remainder)
            children.cellContainerWidgets.removeLast(-remainder * columnCount)
        } else if remainder > 0 {
            for row in rowContent[children.rowNodes.count...] {
                let rowNode = AnyViewGraphNode(
                    for: row,
                    backend: backend,
                    environment: environment
                )
                children.rowNodes.append(rowNode)
                for cellWidget in rowNode.getChildren().widgets(for: backend) {
                    let cellContainer = backend.createContainer()
                    backend.addChild(cellWidget, to: cellContainer)
                    children.cellContainerWidgets.append(AnyWidget(cellContainer))
                }
            }
        }

        backend.setRowCount(ofTable: widget, to: rows.count)
        backend.setColumnLabels(ofTable: widget, to: columnLabels)

        let columnWidth = proposedSize.x / columnCount
        var rowHeights: [Int] = []
        for (rowIndex, (rowNode, content)) in zip(children.rowNodes, rowContent).enumerated() {
            let rowCells = content.layoutableChildren(
                backend: backend,
                children: rowNode.getChildren()
            )

            var cellHeights: [Int] = []
            for rowCell in rowCells {
                let size = rowCell.update(
                    SIMD2(columnWidth, backend.defaultTableRowContentHeight),
                    environment
                )
                cellHeights.append(size.size.y)
            }

            let rowHeight =
                max(cellHeights.max() ?? 0, backend.defaultTableRowContentHeight)
                + backend.defaultTableCellVerticalPadding * 2
            rowHeights.append(rowHeight)

            for (columnIndex, cellHeight) in zip(0..<columnCount, cellHeights) {
                let index = rowIndex * columnCount + columnIndex
                backend.setPosition(
                    ofChildAt: 0,
                    in: children.cellContainerWidgets[index].into(),
                    to: SIMD2(
                        0,
                        (rowHeight - cellHeight) / 2
                    )
                )
            }
        }

        // TODO: Avoid overhead of converting `cellContainerWidgets` to `[AnyWidget]` and back again
        //   all the time.
        backend.setCells(
            ofTable: widget,
            to: children.cellContainerWidgets.map { $0.into() },
            withRowHeights: rowHeights
        )

        let size = proposedSize
        backend.setSize(of: widget, to: size)

        return ViewUpdateResult(
            size: size,
            minimumWidth: 0,
            minimumHeight: 0
        )
    }
}

class TableViewChildren<RowContent: View>: ViewGraphNodeChildren {
    var rowNodes: [AnyViewGraphNode<RowView<RowContent>>] = []
    var cellContainerWidgets: [AnyWidget] = []

    /// Not used, just a protocol requirement.
    var widgets: [AnyWidget] {
        rowNodes.map(\.widget)
    }

    var erasedNodes: [ErasedViewGraphNode] {
        rowNodes.map(ErasedViewGraphNode.init(wrapping:))
    }

    init() {
        rowNodes = []
        cellContainerWidgets = []
    }
}

/// An empty view that simply manages a row's children. Not intended to be rendered directly.
struct RowView<Content: View>: View {
    var body: Content

    init(_ content: Content) {
        self.body = content
    }

    func layoutableChildren<Backend: AppBackend>(
        backend: Backend,
        children: any ViewGraphNodeChildren
    ) -> [LayoutSystem.LayoutableChild] {
        body.layoutableChildren(backend: backend, children: children)
    }

    func children<Backend: AppBackend>(
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: Environment
    ) -> any ViewGraphNodeChildren {
        body.children(backend: backend, snapshots: snapshots, environment: environment)
    }

    func asWidget<Backend: AppBackend>(
        _ children: any ViewGraphNodeChildren,
        backend: Backend
    ) -> Backend.Widget {
        return backend.createContainer()
    }

    func update<Backend: AppBackend>(
        _ widget: Backend.Widget,
        children: any ViewGraphNodeChildren,
        proposedSize: SIMD2<Int>,
        environment: Environment,
        backend: Backend
    ) -> ViewUpdateResult {
        return .empty
    }
}
