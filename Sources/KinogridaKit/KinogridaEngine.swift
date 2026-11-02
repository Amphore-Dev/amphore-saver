import AppKit

// ── Constantes — mode preview (thumbnail System Settings) ─────
private let kPreviewCellSize:  CGFloat = 10      // cellules plus petites → grille visible
private let kPreviewSpeed:     CGFloat = 3_000   // animation plus rapide
private let kPreviewChangeEvery: CGFloat = 10_000 // palette change toutes les 10 s
private let kPreviewFadeDuration: CGFloat = 600

/// Réglages utilisateur (mode normal). Durées en ms.
struct KinogridaOptions {
    var paletteIndex: Int?            = nil       // nil → palette aléatoire à chaque changement
    var cellPixelSize: CGFloat        = 100
    var animSpeed: CGFloat            = 10_000    // ms par cycle d'animation
    var fillPercent: CGFloat          = 0.20
    var changeEvery: CGFloat          = 2 * 60 * 1_000  // 2 min
    var fadeDuration: CGFloat         = 1_200
}

private enum FadeState { case normal, fadingOut, fadingIn }

final class KinogridaEngine {

    private var config: KGGridConfig
    private var grid:   KGGrid
    private var shapes: [KGBaseShape] = []
    private var canvasSize: CGSize = .zero

    private var timeAccumulator: CGFloat = 0
    private var fadeAlpha: CGFloat       = 0
    private var fadeState: FadeState     = .normal

    private let isPreview: Bool
    private let options: KinogridaOptions

    // ── Paramètres selon le mode ───────────────────────────────
    private var cellPixelSize:  CGFloat { isPreview ? kPreviewCellSize    : options.cellPixelSize }
    private var animSpeed:      CGFloat { isPreview ? kPreviewSpeed       : options.animSpeed     }
    private var changeEvery:    CGFloat { isPreview ? kPreviewChangeEvery : options.changeEvery   }
    private var fadeDuration:   CGFloat { isPreview ? kPreviewFadeDuration: options.fadeDuration  }

    private func nextPalette() -> [NSColor] {
        options.paletteIndex.map(KGColors.paletteAtIndex) ?? KGColors.randomPalette()
    }

    // ── Init ──────────────────────────────────────────────────

    init(bounds: NSRect, isPreview: Bool = false, options: KinogridaOptions = KinogridaOptions()) {
        self.isPreview = isPreview
        self.options   = options
        config = KGGridConfig.defaultConfig()
        grid   = KGGrid(rows: 1, cols: 1)
        rebuild(for: bounds)
    }

    // ── Bounds update ─────────────────────────────────────────

    func updateBounds(_ bounds: NSRect) {
        timeAccumulator = 0
        fadeAlpha       = 0
        fadeState       = .normal
        rebuild(for: bounds)
    }

    // ── Rebuild (nouvelle palette + nouvelle grille) ───────────

    private func rebuild(for bounds: NSRect) {
        canvasSize = bounds.size

        config.nbrColumns = max(1, Int(floor(bounds.size.width  / cellPixelSize)))
        config.nbrRows    = max(1, Int(floor(bounds.size.height / cellPixelSize)))
        config.speed      = animSpeed
        config.colors     = nextPalette()
        config.updateForCanvasSize(bounds.size)

        config.showGrid        = false
        config.showLockedCells = false
        config.showPath        = false
        config.showPosition    = false
        config.showStats       = false

        shapes.removeAll()
        grid = KGGrid(rows: config.nbrRows, cols: config.nbrColumns)
        fillGridRandomly()
    }

    private func rebuild() {
        config.colors = nextPalette()
        shapes.removeAll()
        grid = KGGrid(rows: config.nbrRows, cols: config.nbrColumns)
        fillGridRandomly()
    }

    // ── Grid fill ─────────────────────────────────────────────

    private func fillGridRandomly() {
        let maxCells    = max(1, Int(floor(CGFloat(config.nbrColumns * config.nbrRows) * options.fillPercent)))
        var added       = 0
        var attempts    = 0

        while added < maxCells && attempts < 100 {
            let x = KGRandomInt(0, config.nbrColumns - 1)
            let y = KGRandomInt(0, config.nbrRows    - 1)

            if case .empty = grid[y, x] {
                let color = config.colors[KGRandomInt(0, config.colors.count - 1)]
                let shape = randomShape(x: x, y: y, color: color)
                grid[y, x] = .shape(shape)
                shapes.append(shape)
                added    += 1
                attempts  = 0
            }
            attempts += 1
        }
    }

    private func randomShape(x: Int, y: Int, color: NSColor) -> KGBaseShape {
        if KGRandomInt(0, 1) == 0 {
            return KGSquareShape(grid: grid, x: x, y: y, color: color,
                                 radiusPercent: Bool.random() ? 1.0 : 0.0)
        } else {
            return KGArcShape(grid: grid, x: x, y: y, color: color)
        }
    }

    // ── Update ────────────────────────────────────────────────

    func update(deltaTime: CGFloat) {
        switch fadeState {

        case .normal:
            timeAccumulator += deltaTime
            if timeAccumulator >= changeEvery {
                timeAccumulator = 0
                fadeAlpha       = 0
                fadeState       = .fadingOut
            }
            updateShapes(deltaTime: deltaTime)

        case .fadingOut:
            fadeAlpha = min(1, fadeAlpha + deltaTime / fadeDuration)
            if fadeAlpha >= 1 {
                // Grille entièrement noire → regen
                rebuild()
                fadeState = .fadingIn
            }
            updateShapes(deltaTime: deltaTime)

        case .fadingIn:
            fadeAlpha = max(0, fadeAlpha - deltaTime / fadeDuration)
            if fadeAlpha <= 0 { fadeState = .normal }
            updateShapes(deltaTime: deltaTime)
        }
    }

    private func updateShapes(deltaTime: CGFloat) {
        for shape in shapes {
            shape.update(grid: grid, config: config, deltaTime: deltaTime)
        }
        for shape in shapes {
            (shape as? KGArcShape)?.updateProgress(config: config, grid: grid)
        }
    }

    // ── Draw ──────────────────────────────────────────────────

    func draw(in ctx: CGContext) {
        for shape in shapes {
            shape.draw(in: ctx, config: config)
        }

        // ── Overlay de fade (noir transparent) ────────────────
        if fadeAlpha > 0 {
            ctx.setFillColor(red: 0, green: 0, blue: 0, alpha: fadeAlpha)
            ctx.fill(CGRect(origin: .zero, size: canvasSize))
        }
    }
}
