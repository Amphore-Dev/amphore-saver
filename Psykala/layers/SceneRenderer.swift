import AppKit

/// Draws a list of layers the way the web Viewer does.
enum SceneRenderer {
    /// - Parameter layers: API order (top -> bottom); drawn bottom first.
    /// - Parameter context: a y-up CoreGraphics context (NSView / bitmap),
    ///   whose `size` area is already filled with the backdrop color.
    static func draw(_ layers: [BaseLayer], in context: CGContext, size: CGSize, scale: CGFloat) {
        context.saveGState()
        // Web canvas space: origin top-left, y pointing down (see BaseLayer)
        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1, y: -1)

        // Erasing modes (destination-out, xor...) act on a transparent canvas
        // in the web, with the page backdrop showing through: draw into a
        // transparency layer so they never punch through the window itself.
        let isolate = layers.contains { $0.needsTransparentBackdrop }
        if isolate { context.beginTransparencyLayer(auxiliaryInfo: nil) }

        for layer in layers.reversed() {
            layer.draw(in: context, screenSize: size, scale: scale)
        }

        if isolate { context.endTransparencyLayer() }
        context.restoreGState()
    }
}
