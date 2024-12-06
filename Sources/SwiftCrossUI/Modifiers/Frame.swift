extension View {
    /// Positions this view within an invisible frame having the specified minimum size constraints.
    public func frame(
        width: Int? = nil,
        height: Int? = nil,
        alignment: Alignment = .center
    ) -> some View {
        return StrictFrameView(
            self,
            width: width,
            height: height,
            alignment: alignment
        )
    }

    /// Positions this view within an invisible frame having the specified minimum size constraints.
    public func frame(
        minWidth: Int? = nil,
        idealWidth: Int? = nil,
        maxWidth: Int? = nil,
        minHeight: Int? = nil,
        idealHeight: Int? = nil,
        maxHeight: Int? = nil,
        alignment: Alignment = .center
    ) -> some View {
        return FlexibleFrameView(
            self,
            minWidth: minWidth,
            idealWidth: idealWidth,
            maxWidth: maxWidth,
            minHeight: minHeight,
            idealHeight: idealHeight,
            maxHeight: maxHeight,
            alignment: alignment
        )
    }
}

/// The implementation for the ``View/frame(width:height:)`` view modifier.
struct StrictFrameView<Child: View>: TypeSafeView {
    var body: TupleView1<Child>

    /// The exact width to make the view.
    var width: Int?
    /// The exact height to make the view.
    var height: Int?
    /// The alignment of the child within the frame.
    var alignment: Alignment

    /// Wraps a child view with size constraints.
    init(_ child: Child, width: Int?, height: Int?, alignment: Alignment) {
        self.body = TupleView1(child)
        self.width = width
        self.height = height
        self.alignment = alignment
    }

    func children<Backend: AppBackend>(
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: Environment
    ) -> TupleViewChildren1<Child> {
        body.children(backend: backend, snapshots: snapshots, environment: environment)
    }

    func asWidget<Backend: AppBackend>(
        _ children: TupleViewChildren1<Child>,
        backend: Backend
    ) -> Backend.Widget {
        let container = backend.createContainer()
        backend.addChild(children.child0.widget.into(), to: container)
        return container
    }

    func update<Backend: AppBackend>(
        _ widget: Backend.Widget,
        children: TupleViewChildren1<Child>,
        proposedSize: SIMD2<Int>,
        environment: Environment,
        backend: Backend,
        dryRun: Bool
    ) -> ViewSize {
        if dryRun, let width, let height {
            return ViewSize(fixedSize: SIMD2(width, height))
        }

        let proposedSize = SIMD2(
            width ?? proposedSize.x,
            height ?? proposedSize.y
        )

        let childSize = children.child0.update(
            with: body.view0,
            proposedSize: proposedSize,
            environment: environment,
            dryRun: dryRun
        )

        let frameSize = SIMD2(
            width ?? childSize.size.x,
            height ?? childSize.size.y
        )
        if !dryRun {
            let childPosition = alignment.position(
                ofChild: childSize.size,
                in: frameSize
            )
            backend.setSize(of: widget, to: frameSize)
            backend.setPosition(ofChildAt: 0, in: widget, to: childPosition)
        }

        let idealWidth: Int
        let idealHeight: Int
        if let width, let height {
            idealWidth = width
            idealHeight = height
        } else if let width, height == nil {
            idealWidth = width
            idealHeight = childSize.idealHeightForProposedWidth
        } else if let height, width == nil {
            idealHeight = height
            idealWidth = childSize.idealWidthForProposedHeight
        } else {
            idealWidth = childSize.idealSize.x
            idealHeight = childSize.idealSize.y
        }

        let idealWidthForProposedHeight: Int
        let idealHeightForProposedWidth: Int
        if width == nil && height == nil {
            idealWidthForProposedHeight = childSize.idealWidthForProposedHeight
            idealHeightForProposedWidth = childSize.idealHeightForProposedWidth
        } else {
            idealWidthForProposedHeight = idealWidth
            idealHeightForProposedWidth = idealHeight
        }

        return ViewSize(
            size: frameSize,
            idealSize: SIMD2(
                idealWidth,
                idealHeight
            ),
            idealWidthForProposedHeight: idealWidthForProposedHeight,
            idealHeightForProposedWidth: idealHeightForProposedWidth,
            minimumWidth: width ?? childSize.minimumWidth,
            minimumHeight: height ?? childSize.minimumHeight,
            maximumWidth: width.map(Double.init) ?? childSize.maximumWidth,
            maximumHeight: height.map(Double.init) ?? childSize.maximumHeight
        )
    }
}

/// The implementation for the ``View/frame(width:height:)`` view modifier.
struct FlexibleFrameView<Child: View>: TypeSafeView {
    var body: TupleView1<Child>

    var minWidth: Int?
    var idealWidth: Int?
    var maxWidth: Int?
    var minHeight: Int?
    var idealHeight: Int?
    var maxHeight: Int?
    /// The alignment of the child within the frame.
    var alignment: Alignment

    /// Wraps a child view with size constraints.
    init(
        _ child: Child,
        minWidth: Int?,
        idealWidth: Int?,
        maxWidth: Int?,
        minHeight: Int?,
        idealHeight: Int?,
        maxHeight: Int?,
        alignment: Alignment
    ) {
        self.body = TupleView1(child)
        self.minWidth = minWidth
        self.minHeight = minHeight
        self.idealWidth = idealWidth
        self.idealHeight = idealHeight
        self.maxWidth = maxWidth
        self.maxHeight = maxHeight
        self.alignment = alignment
    }

    func children<Backend: AppBackend>(
        backend: Backend,
        snapshots: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment: Environment
    ) -> TupleViewChildren1<Child> {
        body.children(backend: backend, snapshots: snapshots, environment: environment)
    }

    func asWidget<Backend: AppBackend>(
        _ children: TupleViewChildren1<Child>,
        backend: Backend
    ) -> Backend.Widget {
        let container = backend.createContainer()
        backend.addChild(children.child0.widget.into(), to: container)
        return container
    }

    func update<Backend: AppBackend>(
        _ widget: Backend.Widget,
        children: TupleViewChildren1<Child>,
        proposedSize: SIMD2<Int>,
        environment: Environment,
        backend: Backend,
        dryRun: Bool
    ) -> ViewSize {
        var proposedFrameSize = proposedSize
        if let minWidth {
            proposedFrameSize.x = max(proposedFrameSize.x, minWidth)
        }
        if let maxWidth {
            proposedFrameSize.x = min(proposedFrameSize.x, maxWidth)
        }
        if let minHeight {
            proposedFrameSize.y = max(proposedFrameSize.y, minHeight)
        }
        if let maxHeight {
            proposedFrameSize.y = min(proposedFrameSize.y, maxHeight)
        }

        let childSize = children.child0.update(
            with: body.view0,
            proposedSize: proposedFrameSize,
            environment: environment,
            dryRun: dryRun
        )

        // TODO: Fix idealSize propagation. When idealSize isn't possible, we
        //   have to use idealWidthForProposedHeight and
        //   idealHeightForProposedWidth, and sometimes we may also have to
        //   perform an additional dryRun update to probe the child view.

        var frameSize = childSize
        if let minWidth {
            frameSize.size.x = max(frameSize.size.x, minWidth)
            frameSize.minimumWidth = minWidth
            frameSize.idealSize.x = max(frameSize.idealSize.x, minWidth)
            frameSize.idealWidthForProposedHeight = max(
                frameSize.idealWidthForProposedHeight,
                minWidth
            )
        }
        if let maxWidth {
            frameSize.size.x = min(frameSize.size.x, maxWidth)
            frameSize.idealSize.x = min(frameSize.idealSize.x, maxWidth)
            frameSize.maximumWidth = min(childSize.maximumWidth, Double(maxWidth))
            frameSize.idealWidthForProposedHeight = min(
                frameSize.idealWidthForProposedHeight,
                maxWidth
            )
        }

        if let minHeight {
            frameSize.size.y = max(frameSize.size.y, minHeight)
            frameSize.minimumHeight = minHeight
            frameSize.idealSize.y = max(frameSize.idealSize.y, minHeight)
            frameSize.idealHeightForProposedWidth = max(
                frameSize.idealHeightForProposedWidth,
                minHeight
            )
        }
        if let maxHeight {
            frameSize.size.y = min(frameSize.size.y, maxHeight)
            frameSize.idealSize.y = min(frameSize.idealSize.y, maxHeight)
            frameSize.maximumHeight = min(childSize.maximumHeight, Double(maxHeight))
            frameSize.idealHeightForProposedWidth = min(
                frameSize.idealHeightForProposedWidth,
                maxHeight
            )
        }

        if let idealWidth {
            frameSize.idealSize.x = idealWidth
        }
        if let idealHeight {
            frameSize.idealSize.y = idealHeight
        }

        if !dryRun {
            let childPosition = alignment.position(
                ofChild: childSize.size,
                in: frameSize.size
            )
            backend.setSize(of: widget, to: frameSize.size)
            backend.setPosition(ofChildAt: 0, in: widget, to: childPosition)
        }

        return frameSize
    }
}
