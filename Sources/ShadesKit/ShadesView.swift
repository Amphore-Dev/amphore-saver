import ScreenSaver

// MARK: - ShadesView

final class ShadesView: ScreenSaverView {

    private var items: [ShadeItem] = []
    private var config: ShadeConfig!
    private var offset = ShadePoint(x: 0, y: 0)
    private var targetOffset = ShadePoint(x: 0, y: 0)
    private var genCount = 0
    private var time: CFTimeInterval = 0

    // Fade state
    private var fadeOpacity: CGFloat = 0
    private var fadeTarget: CGFloat = 1
    private var fadeStartOpacity: CGFloat = 0
    private var fadeStartTime: CFTimeInterval = 0
    private var isFading = true
    private let fadeDuration: CFTimeInterval = 0.5
    private var pendingRegeneration = false

    // Auto-regeneration timer
    private var regenTimer: CFTimeInterval = 0
    private let regenInterval: CFTimeInterval = 15

    // MARK: - Init

    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        animationTimeInterval = 1.0 / 60.0
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: - Lifecycle

    override func startAnimation() {
        super.startAnimation()
        time = CACurrentMediaTime()
        fadeStartTime = time
        regenTimer = time
        generateFirstScene()
    }

    override func stopAnimation() {
        super.stopAnimation()
        items.removeAll()
    }

    override func animateOneFrame() {
        time = CACurrentMediaTime()
        updateOffset()
        updateFade()

        if time - regenTimer > regenInterval && !isFading {
            triggerRegeneration()
        }

        setNeedsDisplay(bounds)
    }

    override func draw(_ rect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        guard config != nil else { return }

        // Clear to black
        ctx.setFillColor(NSColor.black.cgColor)
        ctx.fill(bounds)

        // Draw all items
        ctx.setLineWidth(config.thickness)
        for item in items {
            item.draw(ctx, config, offset)
        }

        // Fade overlay
        let overlayAlpha = 1 - fadeOpacity
        if overlayAlpha > 0.001 {
            ctx.setFillColor(NSColor.black.withAlphaComponent(overlayAlpha).cgColor)
            ctx.fill(bounds)
        }
    }

    override var hasConfigureSheet: Bool { false }
    override var configureSheet: NSWindow? { nil }

    // MARK: - First generation (text "SHADES" with HOME_COLORS, like JS generate())

    private func generateFirstScene() {
        let forceColor = HOME_COLORS[randInt(0, HOME_COLORS.count - 1)]
        let size = bounds.width / 6

        config = ShadeConfig(
            width: size,
            height: size,
            spacing: 0,
            thickness: CGFloat(randInt(1, 20)),
            nbrShades: 10,
            nbrItemsX: 1,
            nbrItemsY: 1,
            center: ShadePoint(x: bounds.width / 2, y: bounds.height / 2),
            totalWidth: size,
            totalHeight: size,
            gradRatio: 100.0 / 10,
            type: .text,
            colors: [forceColor],
            mainColor: forceColor,
            lineCap: .butt,
            fillFilter: { _, _ in true },
            rotationFilter: { _, _ in false }
        )

        items = [TextShadeItem(x: 0, y: 0, color: forceColor, filled: true)]
        genCount += 1

        fadeStartTime = time
        fadeStartOpacity = 0
        fadeOpacity = 0
        fadeTarget = 1
        isFading = true
        regenTimer = time
    }

    // MARK: - Random generation (like JS handleClick → genConfig + genItems)

    private func generateRandomScene() {
        config = generateConfig()
        generateItems()
        genCount += 1

        fadeStartTime = time
        fadeStartOpacity = 0
        fadeOpacity = 0
        fadeTarget = 1
        isFading = true
        regenTimer = time
    }

    private func triggerRegeneration() {
        fadeStartTime = time
        fadeStartOpacity = fadeOpacity
        fadeTarget = 0
        isFading = true
        pendingRegeneration = true
    }

    // MARK: - Config generation (matches JS genConfig)

    private func generateConfig() -> ShadeConfig {
        let type = ShadeType.allCases[randInt(0, ShadeType.allCases.count - 1)]

        let nbrShades: Int
        let size: CGFloat
        let nbrItemsX: Int
        let nbrItemsY: Int
        let spacing: CGFloat

        if type == .text {
            nbrShades = 10
            size = bounds.width / 6
            nbrItemsX = 1
            nbrItemsY = 1
            spacing = 0
        } else {
            nbrShades = randInt(3, MAX_SHADES_NBR)
            size = randFloat(10, 100)
            nbrItemsX = randInt(3, 20)
            nbrItemsY = randInt(3, 20)
            spacing = randFloat(10, 100)
        }

        let gradRatio = 100.0 / CGFloat(nbrShades)
        let center = ShadePoint(x: bounds.width / 2, y: bounds.height / 2)
        let colors = getRandColors()
        let mainColor = colors[randInt(0, colors.count - 1)]
        let totalWidth = CGFloat(nbrItemsX) * size + CGFloat(max(0, nbrItemsX - 1)) * spacing
        let totalHeight = CGFloat(nbrItemsY) * size + CGFloat(max(0, nbrItemsY - 1)) * spacing

        return ShadeConfig(
            width: size,
            height: size,
            spacing: spacing,
            thickness: CGFloat(randInt(1, 20)),
            nbrShades: nbrShades,
            nbrItemsX: nbrItemsX,
            nbrItemsY: nbrItemsY,
            center: center,
            totalWidth: totalWidth,
            totalHeight: totalHeight,
            gradRatio: gradRatio,
            type: type,
            colors: colors,
            mainColor: mainColor,
            lineCap: getRandLineCap(),
            fillFilter: getRandFilter(),
            rotationFilter: getRandFilter()
        )
    }

    // MARK: - Items generation (matches JS genItems)

    private func generateItems() {
        items.removeAll()

        let colors = genCount > 1 ? getRandColors() : config.colors
        let mainColor = config.mainColor

        for x in 0..<config.nbrItemsX {
            for y in 0..<config.nbrItemsY {
                let idx = randInt(0, colors.count - 1)
                let itemColor = colors[idx]
                let isFilled = config.fillFilter(mainColor, itemColor)
                let hasRotation = config.rotationFilter(mainColor, itemColor)

                let px = CGFloat(x) * config.width + CGFloat(x) * config.spacing
                let py = CGFloat(y) * config.height + CGFloat(y) * config.spacing

                let item: ShadeItem
                switch config.type {
                case .square:
                    item = SquaredShadeItem(x: px, y: py, color: itemColor,
                                            filled: isFilled, lineCap: config.lineCap)
                case .circle:
                    item = CircleShadeItem(x: px, y: py, color: itemColor,
                                           filled: isFilled, lineCap: config.lineCap)
                case .spiral:
                    item = SpiralShadeItem(x: px, y: py, color: itemColor,
                                           filled: isFilled, rotation: true, lineCap: config.lineCap)
                case .triangle:
                    item = TriangleShadeItem(x: px, y: py, color: itemColor,
                                             filled: isFilled, rotation: hasRotation, lineCap: config.lineCap)
                    item.angle = 90 * .pi / 180
                case .text:
                    item = TextShadeItem(x: px, y: py, color: itemColor,
                                         filled: true, lineCap: config.lineCap)
                }

                items.append(item)
            }
        }
    }

    // MARK: - Offset auto-movement (replaces mouse interaction)

    private func updateOffset() {
        let t = time
        let amplitude = min(bounds.width, bounds.height) * 0.15
        targetOffset = ShadePoint(
            x: sin(t * 0.08) * amplitude + cos(t * 0.05) * amplitude * 0.5,
            y: cos(t * 0.06) * amplitude + sin(t * 0.04) * amplitude * 0.5
        )

        let step: CGFloat = 0.02
        offset.x += (targetOffset.x - offset.x) * step
        offset.y += (targetOffset.y - offset.y) * step
    }

    // MARK: - Fade animation (matches JS fade logic)

    private func updateFade() {
        guard isFading else { return }

        let elapsed = time - fadeStartTime
        let progress = min(CGFloat(elapsed / fadeDuration), 1)
        fadeOpacity = fadeStartOpacity + (fadeTarget - fadeStartOpacity) * progress

        if progress >= 1 {
            fadeOpacity = fadeTarget
            isFading = false

            if pendingRegeneration && fadeTarget == 0 {
                pendingRegeneration = false
                generateRandomScene()
            }
        }
    }

    // MARK: - Resize

    override func resize(withOldSuperviewSize oldSize: NSSize) {
        super.resize(withOldSuperviewSize: oldSize)
        config?.center = ShadePoint(x: bounds.width / 2, y: bounds.height / 2)
    }
}
