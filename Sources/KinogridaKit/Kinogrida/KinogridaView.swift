import ScreenSaver

@objc(KinogridaView)
final class KinogridaView: ScreenSaverView {

    private var engine: KinogridaEngine!
    private var lastFrameTime: CFTimeInterval = 0

    // ── Init ──────────────────────────────────────────────────

    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        animationTimeInterval = 1.0 / 30.0
        engine = KinogridaEngine(bounds: frame, isPreview: isPreview)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // ── Animation ─────────────────────────────────────────────

    override func startAnimation() {
        super.startAnimation()
        lastFrameTime = CACurrentMediaTime()
    }

    override func stopAnimation() {
        super.stopAnimation()
    }

    override func animateOneFrame() {
        let now = CACurrentMediaTime()
        let deltaTime: CGFloat = lastFrameTime > 0
            ? CGFloat((now - lastFrameTime) * 1000)
            : 16.67
        lastFrameTime = now

        engine.update(deltaTime: deltaTime)
        needsDisplay = true
    }

    // ── Drawing ───────────────────────────────────────────────

    override func draw(_ rect: NSRect) {
        super.draw(rect)
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        // Fond noir
        ctx.setFillColor(red: 0, green: 0, blue: 0, alpha: 1)
        ctx.fill(bounds)

        // Flip Y (coordonnées canvas : Y=0 en haut)
        ctx.saveGState()
        ctx.translateBy(x: 0, y: bounds.height)
        ctx.scaleBy(x: 1, y: -1)

        engine.draw(in: ctx)

        ctx.restoreGState()
    }

    // ── Pas de config sheet ───────────────────────────────────

    override var hasConfigureSheet: Bool { false }
    override var configureSheet: NSWindow? { nil }
}
