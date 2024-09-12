import CGtk

public class Pango {
    private var pangoContext: OpaquePointer

    /// Create a default pango instance with default context.
    public init() {
        let fontMap = pango_cairo_font_map_new()
        pangoContext = pango_font_map_create_context(fontMap)!
    }

    deinit {
        free(UnsafeMutableRawPointer(pangoContext))
    }

    /// Gets the size of the given text in pixels using the default font. If supplied, `proposedWidth`
    /// acts as a suggested width. The text will attempt to take up less than or equal to the proposed
    /// width but if the text wrapping strategy doesn't allow the text to become as small as required
    /// than it may take up more the proposed width.
    public func getTextSize(
        _ text: String,
        proposedWidth: Double? = nil,
        proposedHeight: Double? = nil
    ) -> (width: Int, height: Int) {
        let layout = pango_layout_new(pangoContext)!
        pango_layout_set_text(layout, text, Int32(text.count))
        pango_layout_set_wrap(layout, PANGO_WRAP_WORD_CHAR)

        if let proposedWidth {
            pango_layout_set_width(
                layout,
                Int32((proposedWidth * Double(PANGO_SCALE)).rounded(.towardZero))
            )
        }
        if let proposedHeight {
            pango_layout_set_height(
                layout,
                Int32((proposedHeight * Double(PANGO_SCALE)).rounded(.towardZero))
            )
        }

        var width: Int32 = 0
        var height: Int32 = 0
        pango_layout_get_pixel_size(layout, &width, &height)

        free(UnsafeMutableRawPointer(layout))

        return (
            Int(width),
            Int(height)
        )
    }
}
