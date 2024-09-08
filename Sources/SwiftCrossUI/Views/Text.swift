/// A text view.
public struct Text: ElementaryView, View {
    /// The string to be shown in the text view.
    private var string: String

    public var flexibility: Int {
        200
    }

    /// Creates a new text view that displays a string with configurable wrapping.
    public init(_ string: String) {
        self.string = string
    }

    public func asWidget<Backend: AppBackend>(
        backend: Backend
    ) -> Backend.Widget {
        return backend.createTextView()
    }

    public func update<Backend: AppBackend>(
        _ widget: Backend.Widget,
        proposedSize: SIMD2<Int>,
        environment: Environment,
        backend: Backend
    ) -> ViewUpdateResult {
        let size = backend.size(of: string, in: proposedSize)
        backend.updateTextView(widget, content: string, environment: environment)
        backend.setSize(of: widget, to: size)
        let lineHeight = backend.computeLineHeight(ofTextRenderedWith: environment)
        return ViewUpdateResult(size: size, minimumWidth: 0, minimumHeight: lineHeight)
    }
}
