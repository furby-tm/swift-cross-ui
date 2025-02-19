import SwiftCrossUI
import CGtk
import Foundation
import Gtk

public struct GtkWidgetRepresentableContext<Coordinator> {
    public let coordinator: Coordinator
    public internal(set) var environment: EnvironmentValues
}

public protocol GtkWidgetRepresentable: View
where Content == Never {
    associatedtype GtkWidgetType: Gtk.Widget
    associatedtype Coordinator = Void

    /// Create the initial GtkWidget instance.
    func makeGtkWidget(context: GtkWidgetRepresentableContext<Coordinator>) -> GtkWidgetType

    /// Update the view with new values.
    /// - Parameters:
    ///   - gtkWidget: The view to update.
    ///   - context: The context, including the coordinator and potentially new environment
    ///   values.
    /// - Note: This may be called even when `context` has not changed.
    func updateGtkWidget(_ gtkWidget: GtkWidgetType, context: GtkWidgetRepresentableContext<Coordinator>)

    /// Make the coordinator for this view.
    ///
    /// The coordinator is used when the view needs to communicate changes to the rest of
    /// the view hierarchy (i.e. through bindings), and is often the view's delegate.
    func makeCoordinator() -> Coordinator

    /// Compute the view's size.
    /// - Parameters:
    ///   - proposal: The proposed frame for the view to render in.
    ///   - gtkWidget: The view being queried for its preferred size.
    ///   - context: The context, including the coordinator and environment values.
    /// - Returns: Information about the view's size. The ``SwiftCrossUI/ViewSize/size``
    /// property is what frame the view will actually be rendered with if the current layout
    /// pass is not a dry run, while the other properties are used to inform the layout engine
    /// how big or small the view can be. The ``SwiftCrossUI/ViewSize/idealSize`` property
    /// should not vary with the `proposal`, and should only depend on the view's contents.
    /// Pass `nil` for the maximum width/height if the view has no maximum size (and therefore
    /// may occupy the entire screen).
    ///
    /// The default implementation uses `gtkWidget.intrinsicContentSize` and `gtkWidget.sizeThatFits(_:)`
    /// to determine the return value.
    func determineViewSize(
        for proposal: SIMD2<Int>, gtkWidget: GtkWidgetType,
        context: GtkWidgetRepresentableContext<Coordinator>
    ) -> ViewSize

    /// Called to clean up the view when it's removed.
    /// - Parameters:
    ///   - gtkWidget: The view being dismantled.
    ///   - coordinator: The coordinator.
    ///
    /// This method is called after all GtkKit lifecycle methods, such as
    /// `gtkWidget.didMoveToSuperview()`.
    ///
    /// The default implementation does nothing.
    static func dismantleGtkWidget(_ gtkWidget: GtkWidgetType, coordinator: Coordinator)
}

extension GtkWidgetRepresentable {
    public static func dismantleGtkWidget(_: GtkWidgetType, coordinator _: Coordinator) {
        // no-op
    }

    public func determineViewSize(
        for proposal: SIMD2<Int>, gtkWidget: GtkWidgetType,
        context _: GtkWidgetRepresentableContext<Coordinator>
    ) -> ViewSize {
        // let intrinsicSize = gtkWidget.intrinsicContentSize
        // let sizeThatFits = gtkWidget.sizeThatFits(
        //     CGSize(width: CGFloat(proposal.x), height: CGFloat(proposal.y)))

        // let roundedSizeThatFits = SIMD2(
        //     Int(sizeThatFits.width.rounded(.up)),
        //     Int(sizeThatFits.height.rounded(.up)))
        // let roundedIntrinsicSize = SIMD2(
        //     Int(intrinsicSize.width.rounded(.awayFromZero)),
        //     Int(intrinsicSize.height.rounded(.awayFromZero)))

        return ViewSize(
            size: SIMD2(proposal.x, proposal.y),
            // The 10 here is a somewhat arbitrary constant value so that it's always the same.
            // See also `Color` and `Picker`, which use the same constant.
            idealSize: SIMD2(10, 10),
            minimumWidth: max(0, proposal.x),
            minimumHeight: max(0, proposal.y),
            maximumWidth: nil,
            maximumHeight: nil
        )
    }
}

extension View
where Self: GtkWidgetRepresentable {
    public var body: Never {
        preconditionFailure("This should never be called")
    }

    public func children<Backend: AppBackend>(
        backend _: Backend,
        snapshots _: [ViewGraphSnapshotter.NodeSnapshot]?,
        environment _: EnvironmentValues
    ) -> any ViewGraphNodeChildren {
        EmptyViewChildren()
    }

    public func layoutableChildren<Backend: AppBackend>(
        backend _: Backend,
        children _: any ViewGraphNodeChildren
    ) -> [LayoutSystem.LayoutableChild] {
        []
    }

    public func asWidget<Backend: AppBackend>(
        _: any ViewGraphNodeChildren,
        backend _: Backend
    ) -> Backend.Widget {
        if let widget = RepresentingWidget(representable: self) as? Backend.Widget {
            return widget
        } else {
            fatalError("GtkWidgetRepresentable requested by \(Backend.self)")
        }
    }

    public func update<Backend: AppBackend>(
        _ widget: Backend.Widget,
        children _: any ViewGraphNodeChildren,
        proposedSize: SIMD2<Int>,
        environment: EnvironmentValues,
        backend _: Backend,
        dryRun: Bool
    ) -> ViewUpdateResult {
        let representingWidget = widget as! RepresentingWidget<Self>
        representingWidget.update(with: environment)

        let size =
            representingWidget.representable.determineViewSize(
                for: proposedSize,
                gtkWidget: representingWidget.subview,
                context: representingWidget.context!
            )

        if !dryRun {
            representingWidget.width = size.size.x
            representingWidget.height = size.size.y
        }

        return ViewUpdateResult.leafView(size: size)
    }
}

extension GtkWidgetRepresentable
where Coordinator == Void {
    public func makeCoordinator() {
        return ()
    }
}

final class RepresentingWidget<Representable: GtkWidgetRepresentable>: BaseWidget {
    var representable: Representable
    var context: GtkWidgetRepresentableContext<Representable.Coordinator>?

    lazy var subview: Representable.GtkWidgetType = {
        let view = representable.makeGtkWidget(context: context!)

        // self.addSubview(view)

        // view.translatesAutoresizingMaskIntoConstraints = false
        // NSLayoutConstraint.activate([
        //     view.topAnchor.constraint(equalTo: self.topAnchor),
        //     view.leadingAnchor.constraint(equalTo: self.leadingAnchor),
        //     view.trailingAnchor.constraint(equalTo: self.trailingAnchor),
        //     view.bottomAnchor.constraint(equalTo: self.bottomAnchor),
        // ])

        return view
    }()

    func update(with environment: EnvironmentValues) {
        if context == nil {
            context = .init(coordinator: representable.makeCoordinator(), environment: environment)
        } else {
            context!.environment = environment
            representable.updateGtkWidget(subview, context: context!)
        }
    }

    init(representable: Representable) {
        self.representable = representable
        super.init()
    }

    deinit {
        if let context {
            Representable.dismantleGtkWidget(subview, coordinator: context.coordinator)
        }
    }
}
