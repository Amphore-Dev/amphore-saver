import AppKit
import ScreensaverCore

public final class KinogridaScene: ScreensaverScene {

    // ── Réglages ──────────────────────────────────────────────

    public static let palette = Setting.choice(
        "kinogrida.palette", "Palette", default: 0,
        options: ["Random", "Ocean", "Sunset", "Dark", "Cyberpunk", "Watermelon"]
    )
    public static let paletteInterval = Setting.slider(
        "kinogrida.paletteInterval", "Palette change every", default: 120,
        range: 10...600, step: 10, unit: .seconds
    )
    public static let cellSize = Setting.slider(
        "kinogrida.cellSize", "Cell size", default: 100,
        range: 40...300, step: 10, unit: .pixels
    )
    public static let fill = Setting.slider(
        "kinogrida.fill", "Grid fill", default: 20,
        range: 5...60, step: 1, unit: .percent
    )
    public static let cycle = Setting.slider(
        "kinogrida.cycle", "Animation cycle", default: 10,
        range: 2...30, step: 0.5, unit: .seconds
    )
    public static let fade = Setting.slider(
        "kinogrida.fade", "Palette fade", default: 1.2,
        range: 0.2...5, step: 0.1, unit: .seconds
    )

    public static let descriptor = SceneDescriptor(
        id: "kinogrida",
        name: "Kinogrida",
        settings: [palette, paletteInterval, cellSize, fill, cycle, fade],
        make: { KinogridaScene(context: $0) }
    )

    // ── État ──────────────────────────────────────────────────

    private let engine: KinogridaEngine
    private var bounds: CGRect
    private var lastFrameTime: CFTimeInterval = 0

    public init(context: SceneContext) {
        let s = context.settings
        let paletteChoice = s.int(Self.palette)
        let options = KinogridaOptions(
            paletteIndex:  paletteChoice == 0 ? nil : paletteChoice - 1,
            cellPixelSize: CGFloat(s.double(Self.cellSize)),
            animSpeed:     CGFloat(s.double(Self.cycle) * 1_000),
            fillPercent:   CGFloat(s.double(Self.fill) / 100),
            changeEvery:   CGFloat(s.double(Self.paletteInterval) * 1_000),
            fadeDuration:  CGFloat(s.double(Self.fade) * 1_000)
        )
        bounds = context.bounds
        engine = KinogridaEngine(bounds: context.bounds, isPreview: context.isPreview, options: options)
    }

    // ── Animation ─────────────────────────────────────────────

    public func start(now: CFTimeInterval) {
        lastFrameTime = now
    }

    public func resume(now: CFTimeInterval) {
        lastFrameTime = now
    }

    public func update(now: CFTimeInterval) {
        let deltaTime: CGFloat = lastFrameTime > 0
            ? CGFloat((now - lastFrameTime) * 1000)
            : 16.67
        lastFrameTime = now

        engine.update(deltaTime: deltaTime)
    }

    public func resize(to bounds: CGRect) {
        self.bounds = bounds
        engine.updateBounds(bounds)
    }

    // ── Drawing ───────────────────────────────────────────────

    public func draw(in ctx: CGContext) {
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
}
