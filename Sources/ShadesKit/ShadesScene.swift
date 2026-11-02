import AppKit
import ScreensaverCore

// MARK: - ShadesScene

public final class ShadesScene: ScreensaverScene {

    // MARK: - Settings

    public static let squares = Setting.toggle("shades.shape.square", "Squares", default: true)
    public static let circles = Setting.toggle("shades.shape.circle", "Circles", default: true)
    public static let spirals = Setting.toggle("shades.shape.spiral", "Spirals", default: true)
    public static let triangles = Setting.toggle("shades.shape.triangle", "Triangles", default: true)
    public static let clock = Setting.toggle("shades.shape.text", "Clock", default: true)
    public static let clockFormat = Setting.choice(
        "shades.clockFormat", "Clock format", default: 0, options: ["24h (HH:mm)", "12h (h:mm)"]
    )
    public static let startWithClock = Setting.toggle("shades.startWithClock", "Start with clock", default: true)
    public static let regenInterval = Setting.slider(
        "shades.regenInterval", "New scene every", default: 15, range: 5...120, step: 1, unit: .seconds
    )
    public static let maxShades = Setting.slider(
        "shades.maxShades", "Max shades", default: 30, range: 3...60, step: 1
    )
    public static let drift = Setting.slider(
        "shades.drift", "Drift amplitude", default: 15, range: 0...40, step: 1, unit: .percent
    )
    public static let fade = Setting.slider(
        "shades.fade", "Scene fade", default: 0.5, range: 0.1...3, step: 0.1, unit: .seconds
    )

    public static let descriptor = SceneDescriptor(
        id: "shades",
        name: "Shades",
        settings: [squares, circles, spirals, triangles, clock, clockFormat,
                   startWithClock, regenInterval, maxShades, drift, fade],
        make: { ShadesScene(context: $0) }
    )

    private var bounds: CGRect
    private let shadeTypes: [ShadeType]
    private let maxShadesNbr: Int
    private let timeFormat: String
    private let startsWithClock: Bool
    private let driftRatio: CGFloat

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
    private let fadeDuration: CFTimeInterval
    private var pendingRegeneration = false

    // Auto-regeneration timer
    private var regenTimer: CFTimeInterval = 0
    private let regenInterval: CFTimeInterval

    // MARK: - Init

    public init(context: SceneContext) {
        let s = context.settings
        bounds = context.bounds

        let toggles: [(ShadeType, Setting)] = [
            (.square, Self.squares), (.circle, Self.circles), (.spiral, Self.spirals),
            (.triangle, Self.triangles), (.text, Self.clock),
        ]
        let enabled = toggles.filter { s.bool($0.1) }.map(\.0)
        shadeTypes = enabled.isEmpty ? ShadeType.allCases : enabled

        maxShadesNbr = Int(s.double(Self.maxShades))
        timeFormat = s.int(Self.clockFormat) == 1 ? "h:mm" : "HH:mm"
        startsWithClock = s.bool(Self.startWithClock) && shadeTypes.contains(.text)
        driftRatio = CGFloat(s.double(Self.drift) / 100)
        regenInterval = s.double(Self.regenInterval)
        fadeDuration = s.double(Self.fade)
    }

    // MARK: - Lifecycle

    public func start(now: CFTimeInterval) {
        time = now
        fadeStartTime = time
        regenTimer = time
        if startsWithClock {
            generateFirstScene()
        } else {
            generateRandomScene()
        }
    }

    public func update(now: CFTimeInterval) {
        time = now
        updateOffset()
        updateFade()

        if time - regenTimer > regenInterval && !isFading {
            triggerRegeneration()
        }
    }

    public func draw(in ctx: CGContext) {
        guard config != nil else {
            ctx.setFillColor(NSColor.black.cgColor)
            ctx.fill(bounds)
            return
        }

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
            timeFormat: timeFormat,
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
        let type = shadeTypes[randInt(0, shadeTypes.count - 1)]

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
            nbrShades = randInt(3, maxShadesNbr)
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
            timeFormat: timeFormat,
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
        let amplitude = min(bounds.width, bounds.height) * driftRatio
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

    public func resize(to bounds: CGRect) {
        self.bounds = bounds
        config?.center = ShadePoint(x: bounds.width / 2, y: bounds.height / 2)
    }
}
